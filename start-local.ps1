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

# 1b. Toolchain / linker check (works for both MSVC and GNU)
$hostTriple = (rustc -vV 2>$null | Select-String '^host:' | ForEach-Object { $_.ToString().Split(' ')[1] })
Write-Host "Active Rust host target: $hostTriple" -ForegroundColor DarkGray
if ($hostTriple -like '*msvc*') {
    $linkExe = (Get-Command link.exe -ErrorAction SilentlyContinue).Source
    if (-not $linkExe) {
        Write-Host ""
        Write-Host "MSVC toolchain selected but link.exe is missing." -ForegroundColor Yellow
        Write-Host "Either install Visual Studio Build Tools (C++ workload, run cmd as Administrator):" -ForegroundColor White
        Write-Host '  winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"' -ForegroundColor White
        Write-Host "Or switch to the GNU toolchain (no VS needed):" -ForegroundColor White
        Write-Host "  rustup toolchain install stable-x86_64-pc-windows-gnu; rustup default stable-x86_64-pc-windows-gnu" -ForegroundColor White
        Write-Host "Then reopen a new terminal and run this script again." -ForegroundColor Yellow
        exit 1
    }
} elseif ($hostTriple -like '*gnu*') {
    $gcc = (Get-Command gcc.exe -ErrorAction SilentlyContinue).Source
    if (-not $gcc) {
        Write-Host ""
        Write-Host "GNU toolchain selected but MinGW gcc/ld not found on PATH." -ForegroundColor Yellow
        Write-Host "Run install-mingw-gnu.bat first (downloads MinGW-w64 and adds it to PATH)." -ForegroundColor White
        exit 1
    }
} else {
    Write-Host "Unknown Rust host target: $hostTriple" -ForegroundColor Red
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
