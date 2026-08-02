@echo off
rem OptionWorkstation local launcher (CMD wrapper)
rem This calls the PowerShell script with execution-policy bypass so it runs without changing your system policy.
rem Keep this window open while you use the app.

powershell -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"
