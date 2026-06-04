@echo off
set FLUTTER=E:\FPT\PRM393\flutter_sdk\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
  echo Flutter chua co tai E:\FPT\PRM393\flutter_sdk\flutter
  pause
  exit /b 1
)
cd /d "%~dp0mobile"
call "%FLUTTER%" pub get
call "%FLUTTER%" run
pause
