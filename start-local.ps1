# OptionWorkstation local launcher (Windows / PowerShell)
# Run this in PowerShell from the project folder:
#   cd C:\Users\SJTUH\optionworkstation
#   .\start-local.ps1
# Keep this window open while you use the app. Close it to stop the server.

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ROOT

Write-Host "OptionWorkstation local launcher" -ForegroundColor Cyan
Write-Host "Project root: $ROOT" -ForegroundColor DarkGray

# 1. Rust toolchain check
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Rust not found. Install it first (requires internet):" -ForegroundColor Yellow
    Write-Host "  1) Open https://rustup.rs in your browser" -ForegroundColor White
    Write-Host "  2) Download rustup-init.exe (64-bit) and run it" -ForegroundColor White
    Write-Host "  3) Choose 'Default Installation' (stable toolchain)" -ForegroundColor White
    Write-Host "  Note: Windows may also need Visual C++ Build Tools; rustup will warn if so." -ForegroundColor DarkGray
    Write-Host "Then reopen PowerShell and run this script again." -ForegroundColor Yellow
    exit 1
}

# 1b. MSVC linker check (Rust on Windows needs link.exe from Visual C++ Build Tools)
$linkExe = (Get-Command link.exe -ErrorAction SilentlyContinue).Source
if (-not $linkExe) {
    Write-Host ""
    Write-Host "Rust is installed, but the MSVC linker (link.exe) is missing." -ForegroundColor Yellow
    Write-Host "Install Visual Studio Build Tools with the C++ workload:" -ForegroundColor Yellow
    Write-Host "  Option A (winget, run cmd as Administrator):" -ForegroundColor White
    Write-Host '    winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"' -ForegroundColor White
    Write-Host "  Option B (manual):" -ForegroundColor White
    Write-Host "    1) https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor White
    Write-Host "    2) Download and run 'Build Tools for Visual Studio 2022' as Administrator" -ForegroundColor White
    Write-Host "    3) Select workload: 'Desktop development with C++'" -ForegroundColor White
    Write-Host "Then reopen a new terminal and run this script again." -ForegroundColor Yellow
    exit 1
}

# 2. Build the release binary (first build downloads crates; takes a few minutes)
Write-Host "Building Rust backend (first run downloads crates, please wait)..." -ForegroundColor Cyan
cargo build --release --manifest-path rust-backend/Cargo.toml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed. See errors above." -ForegroundColor Red
    exit 1
}

# 3. Launch
$BIN = "rust-backend/target/release/option-workstation.exe"
if (-not (Test-Path $BIN)) {
    Write-Host "Binary not found at $BIN after build." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting server -> http://127.0.0.1:7311" -ForegroundColor Green
Write-Host "Open that URL in your browser. Close this window to stop." -ForegroundColor DarkGray
& $BIN
