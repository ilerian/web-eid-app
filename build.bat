#PowerShell -ExecutionPolicy Bypass
$VCPKG_ROOT = "C:\vcpkg"
#$OPENSSL_ROOT_DIR="C:\vcpkg\installed\x64-windows"
#$QT_ROOT="C:\Qt\6.2.4\msvc2019_64"
$QT_ROOT="C:\Qt\6.5.1\msvc2019_64"
$VCPKG_ROOT="C:\vcpkg"
$BUILD_TYPE="RelWithDebInfo"
cmake "-DCMAKE_PREFIX_PATH=${QT_ROOT}" "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" -A x64 -B buildwin -S .
cmake --build buildwin --config ${BUILD_TYPE}
cmake --build buildwin --config ${BUILD_TYPE} --target installer
