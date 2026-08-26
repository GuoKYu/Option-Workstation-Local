@echo off
REM =====================================================================
REM  start.bat - Launch OptionWorkstation (no recompile)
REM  Double-click to run. Close window to stop.
REM =====================================================================

SETLOCAL
SET "ROOT=%~dp0"

echo ============================================================
echo  OptionWorkstation - Starting...
echo  http://127.0.0.1:7311
echo  Close this window to stop.
echo ============================================================
echo.

cd /d "%ROOT%"
rust-backend\target\release\option-workstation.exe

ENDLOCAL
