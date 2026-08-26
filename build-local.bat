@echo off
REM =====================================================================
REM  build-local.bat  v4
REM  Build and launch OptionWorkstation with GNU toolchain.
REM  Pure ASCII - safe for Chinese Windows cmd.
REM =====================================================================

SETLOCAL
SET "MINGW_DIR=C:\mingw64"
SET "ROOT=%~dp0"

REM --- TLS / Network fixes ---
set CARGO_HTTP_SSL_NO_REVOKE=true
set RUSTUP_USE_RUSTLS=1

echo ============================================================
echo  OptionWorkstation - Build v4 (GNU toolchain)
echo ============================================================
echo.

REM 1. Ensure MinGW and Rust on PATH
echo [1/4] Check toolchain ...
set "RUST_BIN=C:\Users\SJTUH\.cargo\bin"
set "PATH=%PATH%;%MINGW_DIR%\bin;%RUST_BIN%"

where gcc.exe >nul 2>&1 || (echo ERROR: gcc missing & pause & exit /b)
where rustup.exe >nul 2>&1 || (echo ERROR: rustup missing & pause & exit /b)
gcc --version | find "gcc"
rustup --version | find "rustup"
echo   Toolchain: OK

REM 2. Ensure GNU toolchain is active (already installed)
echo [2/4] Ensure GNU toolchain active ...
rustup default stable-x86_64-pc-windows-gnu >nul 2>&1
rustc --version | find "gnu"
if errorlevel 1 (
    echo   WARNING: GNU toolchain not found. Installing...
    rustup toolchain install stable-x86_64-pc-windows-gnu --no-self-update
    rustup default stable-x86_64-pc-windows-gnu
)
echo   Done.

REM 3. Build
echo [3/4] Building Rust backend ...
echo   This may take several minutes on first run (downloading crates).
cd /d "%ROOT%"
cargo build --release --manifest-path rust-backend/Cargo.toml
if errorlevel 1 (
    echo.
    echo === BUILD FAILED ===
    echo.
    echo If you see SSL / network errors, your Windows may need a fix:
    echo   1. Open Settings ^> Update ^> check for updates
    echo   2. Or try: setx CARGO_HTTP_SSL_NO_REVOKE true
    echo      then reopen cmd and run this script again
    echo.
    pause
    exit /b
)

REM 4. Launch
echo [4/4] Starting server at http://127.0.0.1:7311
echo Close this window to stop the server.
rust-backend\target\release\option-workstation.exe
ENDLOCAL
