@echo off
REM Windows E2E compatibility entry. The PowerShell runner provides locking,
REM timeouts, logs, and an explicit Windows device.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_tests.ps1" -Suite E2E
exit /b %ERRORLEVEL%
