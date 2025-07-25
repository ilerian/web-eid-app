add_executable(web-eid WIN32 MACOSX_BUNDLE
    ${CMAKE_SOURCE_DIR}/install/appicon.icns
    getcommandhandler.cpp
    InfoPlist.strings
    main.cpp
    web-eid.rc
    web-eid.entitlements
)
set_property(SOURCE web-eid.rc APPEND PROPERTY COMPILE_DEFINITIONS
    PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
    PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
    PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
    PROJECT_VERSION_TWEAK=${PROJECT_VERSION_TWEAK}
)
target_link_libraries(web-eid controller ui pcsc)

if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(PLATFORM x64)
    else()
        set(PLATFORM x86)
    endif()
    if(OPENSSL_ROOT_DIR)
        set(SSL_PATH "${OPENSSL_ROOT_DIR}/bin")
    else()
        get_filename_component(SSL_PATH "${OPENSSL_INCLUDE_DIR}/../bin" ABSOLUTE)
    endif()

    # Define the destination path in the build directory
    set(CARD_LIB_DESTINATION_PATH "${CMAKE_BINARY_DIR}/lib")

    set(WEBEID_PATH web-eid.exe)
    set(BASE_FILE $<TARGET_NAME:web-eid>_${PROJECT_VERSION}.${PLATFORM})
    set(WIX_CMD wix.exe build -nologo
        -arch ${PLATFORM}
        -ext WixToolset.UI.wixext
        -bv WixUIDialogBmp=${CMAKE_SOURCE_DIR}/install/dlgbmp.bmp
        -d MSI_VERSION=${PROJECT_VERSION}
        -d ssl_path="${SSL_PATH}"
        -d qt_suffix="$<$<CONFIG:Debug>:d>"
        -d json=${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.json
        -d jsonfirefox=${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.firefox.json
        -d FIREFOX_URL="${FIREFOX_URL}"
        -d FIREFOX_UUID="${FIREFOX_UUID}"
        -d app_path=$<TARGET_FILE:web-eid>
        -d AKISP11_DLL_PATH="${AKISP11_DLL_PATH}"
        -d ETOKEN_DLL_PATH="${ETOKEN_DLL_PATH}"
        -d CRYPTO_DLL_PATH="${CRYPTO_DLL_PATH}"
        ${CMAKE_SOURCE_DIR}/install/web-eid.wxs
        ${CMAKE_SOURCE_DIR}/install/WelcomeDlg.wxs
        ${CMAKE_SOURCE_DIR}/install/WixUI_Minimal.wxs
    )

    add_custom_target(installer DEPENDS web-eid
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${AKISP11_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ETOKEN_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CRYPTO_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}

        COMMAND ${WIX_CMD} -o "${BASE_FILE}.msi"
        #Build MSI with QT
        COMMAND ${WIX_CMD}  -d qt_path=${qtCore_install_prefix} -o "${BASE_FILE}.qt.msi"
        WORKING_DIRECTORY $<TARGET_FILE_DIR:web-eid>
    )
    add_custom_target(bundle DEPENDS installer
        COMMAND wix.exe build -nologo
            -ext WixToolset.BootstrapperApplications.wixext
            -ext WixToolset.Util.wixext
            -d webeid="${BASE_FILE}"
            -d MSI_VERSION=${PROJECT_VERSION}
            -d path="${CMAKE_SOURCE_DIR}/install"
            "${CMAKE_SOURCE_DIR}/install/plugins.wxs"
            -o "${BASE_FILE}.exe"
        WORKING_DIRECTORY $<TARGET_FILE_DIR:web-eid>
    )
	#message (SIGNCERT: ${SIGNCERT} PASSPARAM:${PASSPARAM})
    if(SIGNCERT)
        list(APPEND SIGNCMD signtool.exe sign /a /v /fd SHA256 /sha1 ${SIGNCERT} ${PASSPARAM}
            /du http://installer.id.ee /tr http://timestamp.digicert.com /td SHA256)
        add_custom_command(TARGET web-eid POST_BUILD
            COMMAND ${SIGNCMD} "$<$<BOOL:${CROSSSIGNCERT}>:/ph;/ac;${CROSSSIGNCERT}>" $<TARGET_FILE:web-eid>
            COMMAND_EXPAND_LISTS
        )
        add_custom_command(TARGET installer POST_BUILD
            COMMAND ${SIGNCMD} "${BASE_FILE}.msi" "${BASE_FILE}.qt.msi"
            WORKING_DIRECTORY $<TARGET_FILE_DIR:web-eid>
        )
        add_custom_command(TARGET bundle POST_BUILD
            COMMAND wix.exe burn detach -nologo "${BASE_FILE}.exe" -engine "${BASE_FILE}.engine.exe"
            COMMAND ${SIGNCMD} "${BASE_FILE}.engine.exe"
            COMMAND wix.exe burn reattach -nologo "${BASE_FILE}.exe" -engine "${BASE_FILE}.engine.exe" -o "${BASE_FILE}.exe"
            COMMAND ${SIGNCMD} "${BASE_FILE}.exe"
            COMMAND del "${BASE_FILE}.engine.exe"
            WORKING_DIRECTORY $<TARGET_FILE_DIR:web-eid>
        )
    endif()
elseif(APPLE)
    set(WEBEID_PATH /Applications/Utilities/web-eid.app/Contents/MacOS/web-eid)
    set(WEBEID_LIB_DIR "/Applications/Utilities/web-eid.app/Contents/MacOS/lib")

    # Define the destination path in the build directory
    set(CARD_LIB_DESTINATION_PATH "$<TARGET_BUNDLE_DIR:web-eid>/Contents/MacOS/lib/")

    set_source_files_properties(${CMAKE_SOURCE_DIR}/install/appicon.icns PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set_source_files_properties(InfoPlist.strings PROPERTIES MACOSX_PACKAGE_LOCATION Resources/en.lproj)
    set_target_properties(web-eid PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/MacOSXBundleInfo.plist.in)
    configure_file(${CMAKE_SOURCE_DIR}/install/macos-postinstall.in root_firefox_scripts/postinstall @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/install/macos-native-preinstall.in root_native_scripts/preinstall @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/install/macos-native-postinstall.in root_native_scripts/postinstall @ONLY)

    install(TARGETS web-eid DESTINATION /Applications/Utilities COMPONENT main)

    #install(FILES ${AKISP11_DLL_PATH} ${ETOKEN_DLL_PATH} ${CRYPTO_DLL_PATH} COMPONENT main DESTINATION ${WEBEID_LIB_DIR})

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.json COMPONENT chrome
        DESTINATION "/Library/Google/Chrome/NativeMessagingHosts")
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.firefox.json COMPONENT firefox
        DESTINATION "/Library/Application Support/Mozilla/NativeMessagingHosts" RENAME eu.webeid.json)
    install(FILES ${CMAKE_SOURCE_DIR}/install/ncibgoaomkmdpilpocfeponihegamlic.json COMPONENT chrome
        DESTINATION "/Library/Application Support/Google/Chrome/External Extensions")


    add_custom_target(deploy-card-libs DEPENDS web-eid
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CARD_LIB_DESTINATION_PATH}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${AKISP11_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ETOKEN_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CRYPTO_DLL_PATH} ${CARD_LIB_DESTINATION_PATH}
            )

    add_custom_target(macdeployqt DEPENDS web-eid deploy-card-libs
        COMMAND ${qtCore_install_prefix}/macdeployqt $<TARGET_BUNDLE_DIR:web-eid>
    )
    add_custom_target(installer-native DEPENDS macdeployqt
        COMMAND rm -rf root_native
        COMMAND DESTDIR=root_native ${CMAKE_COMMAND} --install . --component main
        COMMAND pkgbuild --root root_native --scripts root_native_scripts --analyze root_native_analyzed.plist
        COMMAND plutil -replace BundleIsRelocatable -bool NO root_native_analyzed.plist
        COMMAND pkgbuild --root root_native --scripts root_native_scripts --identifier "eu.web-eid.$<TARGET_NAME:web-eid>"
            "$<$<BOOL:${SIGNCERT}>:--sign;${SIGNCERT}>"
            --version "${PROJECT_VERSION}" $<TARGET_NAME:web-eid>-native_${PROJECT_VERSION}.pkg
            --component-plist root_native_analyzed.plist
        COMMAND_EXPAND_LISTS
    )
    add_custom_target(installer-firefox DEPENDS installer-native
        COMMAND rm -rf root_firefox
        COMMAND DESTDIR=root_firefox ${CMAKE_COMMAND} --install . --component firefox
        COMMAND pkgbuild --root root_firefox --scripts root_firefox_scripts --identifier "eu.web-eid.$<TARGET_NAME:web-eid>-firefox"
            "$<$<BOOL:${SIGNCERT}>:--sign;${SIGNCERT}>"
            --version "${PROJECT_VERSION}" $<TARGET_NAME:web-eid>-firefox_${PROJECT_VERSION}.pkg
        COMMAND_EXPAND_LISTS
    )
    add_custom_target(installer-chrome DEPENDS installer-native
        COMMAND rm -rf root_chrome
        COMMAND DESTDIR=root_chrome ${CMAKE_COMMAND} --install . --component chrome
        COMMAND pkgbuild --root root_chrome --identifier "eu.web-eid.$<TARGET_NAME:web-eid>-chrome"
            "$<$<BOOL:${SIGNCERT}>:--sign;${SIGNCERT}>"
            --version "${PROJECT_VERSION}" $<TARGET_NAME:web-eid>-chrome_${PROJECT_VERSION}.pkg
        COMMAND_EXPAND_LISTS
    )
    add_custom_target(installer DEPENDS installer-chrome installer-firefox
        COMMAND mkdir -p packages
        COMMAND cp web-eid-native_*.pkg packages/web-eid-native.pkg
        COMMAND cp web-eid-chrome_*.pkg packages/web-eid-chrome.pkg
        COMMAND cp web-eid-firefox_*.pkg packages/web-eid-firefox.pkg
        COMMAND productbuild --distribution ${CMAKE_SOURCE_DIR}/install/distribution.xml
            "$<$<BOOL:${SIGNCERT}>:--sign>"
            "$<$<BOOL:${SIGNCERT}>:Developer ID Installer: ${SIGNCERT}>"
            --resources ${CMAKE_SOURCE_DIR}/install/
            --version "${PROJECT_VERSION}" --package-path packages/ web-eid_${PROJECT_VERSION}.pkg
        COMMAND mkdir -p tmp
        COMMAND cp ${CMAKE_SOURCE_DIR}/install/DS_Store tmp/.DS_Store
        COMMAND cp web-eid_${PROJECT_VERSION}.pkg tmp/Web-eID.pkg
        COMMAND cp ${CMAKE_SOURCE_DIR}/install/background.png ${CMAKE_SOURCE_DIR}/install/uninstall.sh tmp

        COMMAND setfile -a E tmp/Web-eID.pkg
        COMMAND setfile -a V tmp/background.png

    )
    if(SIGNCERT)

        add_custom_command( TARGET installer POST_BUILD
                COMMAND xcrun notarytool submit tmp/Web-eID.pkg --key "${NOTARIZATION_KEY_PATH}" --key-id "${NOTARIZATION_KEY_ID}" --issuer "${NOTARIZATION_KEY_ISSUER}" --wait
                COMMAND xcrun stapler staple tmp/Web-eID.pkg
        )

        add_custom_command(TARGET macdeployqt POST_BUILD
            COMMAND codesign -f -o runtime --timestamp -s "Developer ID Application: ${SIGNCERT}"
                $<TARGET_BUNDLE_CONTENT_DIR:web-eid>/Frameworks/*.*
                $<TARGET_BUNDLE_CONTENT_DIR:web-eid>/PlugIns/*/*
            COMMAND codesign -f -o runtime --timestamp -s "Developer ID Application: ${SIGNCERT}"
                --entitlements ${CMAKE_CURRENT_LIST_DIR}/web-eid.entitlements
                $<TARGET_BUNDLE_DIR:web-eid>
        )

    endif()

    add_custom_command( TARGET installer POST_BUILD
        COMMAND hdiutil create web-eid_${PROJECT_VERSION}.dmg -ov -volname web-eid -srcfolder tmp
        COMMAND_EXPAND_LISTS
    )

    if (SIGNCERT)
        add_custom_command(TARGET installer POST_BUILD
                COMMAND codesign -f --timestamp -s "Developer ID Application: ${SIGNCERT}" web-eid_${PROJECT_VERSION}.dmg
                )
    endif()
else()
    option(BUNDLE_XPI "Download and bundle the Firefox extension" OFF)
    include(GNUInstallDirs)
    if (BUNDLE_XPI)
      file(DOWNLOAD ${FIREFOX_URL} ${CMAKE_CURRENT_BINARY_DIR}/${FIREFOX_UUID}.xpi)
    endif()
    set(WEBEID_PATH ${CMAKE_INSTALL_FULL_BINDIR}/web-eid)
    install(TARGETS web-eid DESTINATION ${CMAKE_INSTALL_BINDIR})
    if(EXISTS /etc/debian_version)
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.firefox.json
            DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/mozilla/native-messaging-hosts RENAME eu.webeid.json)
    else()
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.firefox.json
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/mozilla/native-messaging-hosts RENAME eu.webeid.json)
    endif()
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.json
        DESTINATION ${CMAKE_INSTALL_DATADIR}/web-eid)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.json
        DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/chromium/native-messaging-hosts)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eu.webeid.json
        DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/opt/chrome/native-messaging-hosts)
    install(FILES ${CMAKE_SOURCE_DIR}/install/ncibgoaomkmdpilpocfeponihegamlic.json
        DESTINATION ${CMAKE_INSTALL_DATADIR}/google-chrome/extensions)
    install(FILES ${CMAKE_SOURCE_DIR}/install/ncibgoaomkmdpilpocfeponihegamlic.json
        DESTINATION ${CMAKE_INSTALL_DATADIR}/chromium/extensions)
    install(FILES ${CMAKE_SOURCE_DIR}/install/web-eid.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    if (BUNDLE_XPI)
      install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${FIREFOX_UUID}.xpi
              DESTINATION ${CMAKE_INSTALL_DATADIR}/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384})
    endif()
    foreach(RES 16 32 128 256 512)
        install(
            FILES ${CMAKE_SOURCE_DIR}/install/appicon_${RES}.png
            DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/${RES}x${RES}/apps/
            RENAME web-eid.png
        )
    endforeach()

    add_custom_target(installer
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMAND dch --distribution unstable -v ${PROJECT_VERSION} "Release: ${PROJECT_VERSION}."
        COMMAND dpkg-buildpackage -us -uc
    )
endif()
configure_file(${CMAKE_SOURCE_DIR}/install/eu.webeid.json.cmake eu.webeid.json @ONLY)
configure_file(${CMAKE_SOURCE_DIR}/install/eu.webeid.firefox.json.cmake eu.webeid.firefox.json @ONLY)
