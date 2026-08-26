@echo off
REM =====================================================================
REM  install-mingw-gnu.bat  (v2 - NON-GITHUB sources only)
REM  Downloads MinGW-w64 GCC toolchain and switches Rust to GNU.
REM  No admin needed. No GitHub. No Microsoft domains.
REM
REM  Sources tried (in order):
REM    1. nuwen.net        - standalone MinGW distro (self-extracting .exe)
REM    2. SourceForge      - winlibs mirror (if available)
REM
REM  After done, run start-local.bat to build and launch.
REM =====================================================================

SETLOCAL
SET "MINGW_DIR=C:\mingw64"

echo ============================================================
echo  OptionWorkstation - MinGW/GNU Toolchain Installer
echo  Network: GitHub is BLOCKED on this machine.
echo  Using alternative (non-GitHub) download sources.
echo ============================================================
echo.

REM ---- Source 1: nuwen.net MinGW (self-extracting, NOT on GitHub) ----
echo [1/3] Trying nuwen.net MinGW distro ...
echo   URL: https://nuwen.net/files/mingw/mingw-20.0.exe
echo.

SET "NUWEN_EXE=%TEMP%\mingw-20.0.exe"
curl -L -o "%NUWEN_EXE%" https://nuwen.net/files/mingw/mingw-20.0.exe

REM Check if download succeeded (file > 1MB)
powershell -NoProfile -Command "if((Test-Path '%NUWEN_EXE%') -and ((Get-Item '%NUWEN_EXE%').Length -gt 1000000)){exit 0}else{exit 1}"
if not errorlevel 1 (
    echo   Download OK.

    echo.
    echo [2/3] Running nuwen installer (self-extracting archive) ...
    echo   It will open a dialog. Extract to: C:\mingw64
    echo   (Click "Extract" / "Unzip" and set path to C:\mingw64)
    echo.
    "%NUWEN_EXE%"
    if not exist "%MINGW_DIR%\bin\gcc.exe" (
        echo.
        echo WARNING: gcc.exe not found at %MINGW_DIR%\bin\ after extraction.
        echo Did you extract to C:\mingw64 ?
        echo If you extracted elsewhere, note the path - we will use it.
    )
) else (
    echo   nuwen.net FAILED.
    echo.
    echo ============================================================
    echo  ALL DOWNLOAD SOURCES FAILED.
    echo.
    echo  Your network blocks both GitHub AND nuwen.net.
    echo.
    echo  OPTIONS:
    echo   A) Use mobile hotspot / different network, then re-run this script
    echo   B) Manually download from another device/network:
    echo      https://nuwen.net/files/mingw/mingw-20.0.exe
    echo      Copy file to this PC, run it, extract to C:\mingw64
    echo   C) If you have MSYS2 installed already:
    echo      Run MSYS2 UCRT64 terminal, then type:
    echo      pacman -S mingw-w64-ucrt-x86_64-gcc
    echo ============================================================
    pause
    exit /b
)

REM ---- Verify gcc exists somewhere ----
echo.
echo [3/3] Verifying MinGW installation ...

REM Check canonical location first
if exist "%MINGW_DIR%\bin\gcc.exe" (
    echo   Found: %MINGW_DIR%\bin\gcc.exe
    goto :ADD_PATH
)

REM Check common alternate locations
if exist "C:\msys64\ucrt64\bin\gcc.exe" (
    echo   Found MSYS2 UCRT64 gcc at C:\msys64\ucrt64\bin\
    SET "MINGW_DIR=C:\msys64\ucrt64"
    goto :ADD_PATH
)
if exist "C:\msys64\mingw64\bin\gcc.exe" (
    echo   Found MSYS2 mingw64 gcc at C:\msys64\mingw64\bin\
    SET "MINGW_DIR=C:\msys64\mingw64"
    goto :ADD_PATH
)

echo.
echo ERROR: gcc.exe NOT found anywhere.
echo Please make sure MinGW was extracted to C:\mingw64
pause
exit /b

:ADD_PATH
echo   Adding %MINGW_DIR%\bin to PATH ...
echo %PATH% | find /i "mingw64" >nul || setx PATH "%PATH%;%MINGW_DIR%\bin"
set "PATH=%PATH%;%MINGW_DIR%\bin"

REM Switch Rust to GNU
echo.
echo Switching Rust to GNU toolchain (downloads ~50MB) ...
rustup toolchain install stable-x86_64-pc-windows-gnu
rustup default stable-x86_64-pc-windows-gnu

echo.
echo ============================================================
echo  DONE!
echo.
echo  GCC location: %MINGW_DIR%\bin\gcc.exe
echo  Rust target:  stable-x86_64-pc-windows-gnu
echo.
echo  Now OPEN A NEW cmd window and run:
echo.
echo      cd C:\Users\SJTUH\optionworkstation
echo      start-local.bat
echo.
echo  Browser: http://127.0.0.1:7311
echo ============================================================
pause
ENDLOCAL
