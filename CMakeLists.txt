cmake_minimum_required(VERSION 3.16)

if(NOT EXISTS "${CMAKE_SOURCE_DIR}/lib/libelectronic-id/README.md")
    message(FATAL_ERROR "libelectronic-id submodule directory empty, did you 'git clone --recursive'?")
endif()

if($ENV{BUILD_NUMBER})
    set(BUILD_NUMBER $ENV{BUILD_NUMBER})
elseif($ENV{CI_PIPELINE_IID})
    set(BUILD_NUMBER $ENV{CI_PIPELINE_IID})
else()
    set(BUILD_NUMBER 0)
endif()
project(web-eid VERSION 2.6.0.${BUILD_NUMBER})

if(DEFINED ENV{DIGPASS})
	set(PASSPARAM $ENV{DIGPASS})
else()
    set(PASSPARAM /s MY)
endif()

if(DEFINED ENV{SIGNCERT})
    set(SIGNCERT_PARAM $ENV{SIGNCERT})
else()
    set(SIGNCERT_PARAM "")
endif()

# Define the source path of the DLL file
if(WIN32)
    # Define the source path of the DLL file for Windows
    set(AKISP11_DLL_PATH "${CMAKE_SOURCE_DIR}/lib/win/akisp11.dll")
    set(ETOKEN_DLL_PATH "${CMAKE_SOURCE_DIR}/lib/win/eToken.dll")
elseif(APPLE)
    # Define the source path of the DLL file for macOS
    set(AKISP11_DLL_PATH "${CMAKE_SOURCE_DIR}/lib/mac/libakisp11.dylib")
    set(ETOKEN_DLL_PATH "${CMAKE_SOURCE_DIR}/lib/mac/libeToken.dylib")
endif()
set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
set(MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION_TWEAK})
set(SEMVER_VERSION_STRING "${MACOSX_BUNDLE_SHORT_VERSION_STRING}+${PROJECT_VERSION_TWEAK}")
set(CMAKE_POSITION_INDEPENDENT_CODE YES)
set(CPACK_GENERATOR RPM)
set(CPACK_PACKAGE_CONTACT "ILERIAN <destek@imzayeri.com>")
set(CPACK_PACKAGE_VENDOR ILERIAN)
set(CPACK_PACKAGING_INSTALL_PREFIX /usr)
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_RELEASE_DIST ON)
include(CPack)

set(FIREFOX_UUID "{e68418bc-f2b0-4459-a9ea-3e72b6751b07}" CACHE STRING "Firefox Extension UUID")
set(FIREFOX_URL "https://addons.mozilla.org/firefox/downloads/latest/web-eid-webextension/latest.xpi" CACHE STRING "Mozilla AMO URL")

set(SIGNCERT ${SIGNCERT_PARAM} CACHE STRING "Common name of certificate to used sign binaries, empty skips signing  (Windows/macOS)")
set(CROSSSIGNCERT "" CACHE STRING "Common name of certificate to used cross sign binaries, empty skips signing (Windows)")
set(SAFARI_PROVISIONPROFILE "" CACHE STRING "Provision profile to include in application (macOS)")

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} 5.12.0 REQUIRED COMPONENTS Core Widgets Network Test LinguistTools Svg DBus)
get_target_property(qtCore_install_prefix Qt${QT_VERSION_MAJOR}::qmake IMPORTED_LOCATION)
get_filename_component(qtCore_install_prefix ${qtCore_install_prefix} DIRECTORY)

add_subdirectory(lib/libelectronic-id)

set(CMAKE_AUTOMOC ON)
add_subdirectory(src/ui)
add_subdirectory(src/controller)
add_subdirectory(src/app)
if(APPLE)
    add_subdirectory(src/mac)
endif()

enable_testing()
add_subdirectory(tests/mock-ui)
add_subdirectory(tests/tests)
