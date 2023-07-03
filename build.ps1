#PowerShell -ExecutionPolicy Bypass
param(
  #[string]$QT_ROOT="C:\Qt\6.5.1\msvc2019_64",
  [string]$QT_ROOT="C:\Qt\5.15.2\msvc2019_64",
  [string]$VCPKG_ROOT="C:\vcpkg",
  [string]$BUILD_TYPE="RelWithDebInfo"
  #[string]$BUILD_TYPE="Debug"
)

$PROJECT_ROOT = split-path -parent $MyInvocation.MyCommand.Definition

#Push-Location -Path "$PROJECT_ROOT\build"
#& $cmake -A x64 "-DCMAKE_TOOLCHAIN_FILE=$vcpkgroot\scripts\buildsystems\vcpkg.cmake" "-DQt5_DIR=$qtdir/lib/cmake/Qt5" ..
#& $cmake --build .
#Pop-Location

cmake "-DCMAKE_PREFIX_PATH=${QT_ROOT}" "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" -A x64 -B buildwin$BUILD_TYPE -S .
cmake --build buildwin$BUILD_TYPE --config ${BUILD_TYPE}
cmake --build buildwin$BUILD_TYPE --config ${BUILD_TYPE} --target installer
