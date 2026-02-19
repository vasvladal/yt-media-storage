@echo off
echo === Checking vcpkg FFmpeg installation ===
if exist "c:\ffmpeg-8.0\libavcodec\avcodec.h" (
    echo [OK] FFmpeg headers found
) else (
    echo [FAIL] FFmpeg headers not found
)

echo === Checking pkg-config ===
where pkg-config >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] pkg-config found
    pkg-config --modversion libavcodec 2>nul
    if %errorlevel% equ 0 (
        echo [OK] libavcodec found by pkg-config
    ) else (
        echo [FAIL] libavcodec not found by pkg-config
    )
) else (
    echo [FAIL] pkg-config not found in PATH
)

echo === Checking PKG_CONFIG_PATH ===
echo PKG_CONFIG_PATH=%PKG_CONFIG_PATH%

pause