@echo off
echo === FFmpeg Installation Checker ===
echo.

set INSTALLS[0]=C:\ProgramData\chocolatey
set INSTALLS[1]=c:\Program Files\ffmpeg-1011
set INSTALLS[2]=d:\GitHub\Faster-Whisper-XXL-GUI\dist

setlocal enabledelayedexpansion

for /l %%n in (0,1,2) do (
    set INST=!INSTALLS[%%n]!
    echo Checking !INST!...
    
    if exist "!INST!" (
        echo   [OK] Directory exists
        
        REM Check for headers
        set HEADER_FOUND=0
        for /r "!INST!" %%f in (*avcodec.h) do (
            if exist "%%f" (
                echo   [FOUND] Headers at: %%~dpf
                set HEADER_FOUND=1
            )
        )
        if !HEADER_FOUND!==0 echo   [MISSING] No headers found
        
        REM Check for libraries
        set LIB_FOUND=0
        for /r "!INST!" %%f in (*avcodec.lib) do (
            if exist "%%f" (
                echo   [FOUND] Libraries at: %%~dpf
                set LIB_FOUND=1
            )
        )
        if !LIB_FOUND!==0 echo   [MISSING] No libraries found
        
        REM Check for pkgconfig files
        set PC_FOUND=0
        for /r "!INST!" %%f in (*.pc) do (
            if exist "%%f" (
                echo   [FOUND] pkgconfig files at: %%~dpf
                set PC_FOUND=1
            )
        )
        if !PC_FOUND!==0 echo   [MISSING] No pkgconfig files
    ) else (
        echo   [ERROR] Directory does not exist
    )
    echo.
)

echo === Summary ===
echo.
echo For CMake to find FFmpeg, you need:
echo 1. Headers (libavcodec/avcodec.h, etc.)
echo 2. Libraries (avcodec.lib, avformat.lib, etc.)
echo 3. Optional but helpful: pkgconfig .pc files
pause