#PowerShell -ExecutionPolicy Bypass
param(
  [string]$QT_ROOT = "c:\misc\Qt\6.7.3\msvc2019_64\",
  [string]$VCPKG_ROOT = "C:\misc\vcpkg",
  [string]$BUILD_TYPE = "RelWithDebInfo"
)
$env:Path = 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\WINDOWS\System32\WindowsPowerShell\v1.0\' + $env:Path


#$env:PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433\bin\HostARM64\x86";"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433\bin\HostARM64\arm64";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VC\VCPackages";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TestWindow";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer";"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\bin\Roslyn";"C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\";"C:\Program Files\Microsoft Visual Studio\2022\Community\Team Tools\DiagnosticsHub\Collector";"C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\\arm64";"C:\Program Files (x86)\Windows Kits\10\bin\\arm64";"C:\Program Files\Microsoft Visual Studio\2022\Community\\MSBuild\Current\Bin\arm64";C:\Windows\Microsoft.NET\Framework64\v4.0.30319;"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\";"C:\Program Files\Parallels\Parallels Tools\Applications";"C:\Program Files (x86)\Common Files\Oracle\Java\java8path";"C:\Program Files (x86)\Common Files\Oracle\Java\javapath";C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;"C:\Program Files\SafeNet\Authentication\SAC\x64";"C:\Program Files\SafeNet\Authentication\SAC\x32";"C:\Program Files\dotnet\";"C:\Program Files\Git\cmd";"C:\Program Files\Git\mingw64\bin";"C:\Program Files\Git\usr\bin";C:\Users\kurtulus\AppData\Local\Microsoft\WindowsApps;C:\Users\kurtulus\.dotnet\tools;"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja";"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VC\Linux\bin\ConnectionManagerExe"

#Push-Location -Path "$PROJECT_ROOT\build"
#& $cmake -A x64 "-DCMAKE_TOOLCHAIN_FILE=$vcpkgroot\scripts\buildsystems\vcpkg.cmake" "-DQt5_DIR=$qtdir/lib/cmake/Qt5" ..
#& $cmake --build .
#Pop-Location

& cmake "-DCMAKE_PREFIX_PATH=${QT_ROOT}" "-DQt6_DIR=${QT_ROOT}" "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" -A x64 -B buildwin -S .
& cmake --build buildwin --config ${BUILD_TYPE}
& cmake --build buildwin --config ${BUILD_TYPE} --target installer