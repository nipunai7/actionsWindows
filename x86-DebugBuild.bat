@echo off

REM Set the current directory as the working directory
cd /d "%~dp0"

REM Check if the script is running with administrative privileges
NET SESSION >nul 2>&1
if %errorLevel% == 0 (
    goto :runScript
) else (
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs" >nul 2>&1
    exit
)

:runScript
REM Define the name of the process to stop
set "processName=bcc_com"

REM Stop the bcc_com if it's running
taskkill /f /im "%processName%.exe" >nul 2>&1

echo "Existing bcc_com process stopped (if running)"

:: Setting source paths
:: Set the path to the Visual Studio environment script (change the path according to your installation)
call "C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/VC/Auxiliary/Build/vcvarsall.bat" x86

:: Set the path to CMake executable (if not in PATH)
set CMAKE_PATH="C:/Program Files/CMake/bin/cmake.exe"

:: Set the path to Ninja executable (if not in PATH)
set NINJA_PATH="C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/Ninja/ninja.exe"

:: Set the relative path to the build directory from the location of the batch file
set RELATIVE_BUILD_DIR=..\..\out\build

:: Compute the absolute path to the build directory
set BUILD_DIR=%CD%\%RELATIVE_BUILD_DIR%

:: Set the relative path to the source directory containing your CMakeLists.txt
set CMAKE_SOURCE_DIR="../../../"


:: Building the DCS Camera SDK ---------------------------------------------------------------------------------------------------------------
:: Remove the existing build directory if it exists
if exist %BUILD_DIR% (
    rmdir /s /q %BUILD_DIR%\x86-Debug
)

:: Create the build directory
mkdir %BUILD_DIR%\x86-Debug

:: Change directory to the build directory
cd /d %BUILD_DIR%\x86-Debug

:: Run CMake to generate the cache and project files with the specified generator and settings
%CMAKE_PATH% -S %CMAKE_SOURCE_DIR% -B . -GNinja ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -DCMAKE_C_COMPILER="C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/VC/Tools/MSVC/14.29.30133/bin/Hostx86/x86/cl.exe" ^
    -DCMAKE_C_FLAGS_Debug="/MDd /Zi /Ob0 /Od /RTC1"
:: Check if CMake succeeded
if %errorlevel% neq 0 (
    echo CMake configuration failed.
    exit /b %errorlevel%
) else (
    echo CMake configuration succeeded.
)

:: Build the project using Ninja with verbose output
%NINJA_PATH% -v

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

:: Build the COM MC SDK Wrapper ---------------------------------------------------------------------------------------------------------------
echo "Building COM MC SDK Wrapper"

:: Set the path to MSBuild executable (if not in PATH)
set MSBUILD_PATH="C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/MSBuild/Current/Bin/MSBuild.exe"

:: Set the path to the solution file
set SOLUTION_PATH=%CMAKE_SOURCE_DIR%\sdk_wrappers\com_mc\camera_sdk.sln

:: Specify the project name to build
set PROJECT_NAME="camera_sdk"

:: Build the specified project using MSBuild
%MSBUILD_PATH% %SOLUTION_PATH% /t:%PROJECT_NAME% /p:Configuration=Debug /p:Platform=Win32

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

:: Build the Imaging Library -----------------------------------------------------------------------------------------------------------------
echo "Building Imaging Library"

:: Set the path to the solution file
set SOLUTION_PATH=%CMAKE_SOURCE_DIR%\imaging_library\CameraImagingLib.sln

:: Build the specified project using MSBuild
%MSBUILD_PATH% %SOLUTION_PATH% /p:Configuration=Debug /p:Platform=x86

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

:: Build Image Proc Wrapper -----------------------------------------------------------------------------------------------------------------
echo "Building Image Proc Wrapper"

:: Set the path to the solution file
set SOLUTION_PATH=%CMAKE_SOURCE_DIR%\imaging_library\image_proc_wrapper\image_proc.sln

:: Build the specified project using MSBuild
%MSBUILD_PATH% %SOLUTION_PATH% /p:Configuration=Debug /p:Platform=x86

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

:: Build C++ Sample Applicaiton ---------------------------------------------------------------------------------------------------------------
echo "Building C++ Sample Application"

:: Set the path to the solution file
set SOLUTION_PATH=%CMAKE_SOURCE_DIR%\sample_apps\gui\mfc\zebra_camera_sdk_sample_application\zebra_camera_sdk_sample_application.sln

:: Specify the project name to build
set PROJECT_NAME="zebra_camera_sdk_sample_application"

:: Build the specified project using MSBuild
%MSBUILD_PATH% %SOLUTION_PATH% /t:%PROJECT_NAME% /p:Configuration=DevDebug /p:Platform=x86

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

:: Build C# Sample Applicaiton ---------------------------------------------------------------------------------------------------------------
echo "Building C# Sample Application"

:: Set the path to the solution file
set SOLUTION_PATH=%CMAKE_SOURCE_DIR%\sample_apps\.net\c_sharp\c_sharp_sample_application.sln

:: Specify the project name to build
set PROJECT_NAME="CameraSDKSampleApp"

:: Build the specified project using MSBuild
%MSBUILD_PATH% %SOLUTION_PATH% /t:%PROJECT_NAME% /p:Configuration=DevDebug /p:Platform=x86

:: Check if the build succeeded
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b %errorlevel%
) else (
    echo Build succeeded.
)

pause
