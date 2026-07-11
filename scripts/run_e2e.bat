@echo off
REM 一键运行 E2E 测试（需要连接模拟器或真机）
cd /d "%~dp0..\flutter_app"
flutter test integration_test/ -v
if %ERRORLEVEL% neq 0 (
    echo E2E test failed - check simulator/emulator connection
    pause
    exit /b %ERRORLEVEL%
)
echo All E2E tests passed!
