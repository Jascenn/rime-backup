@echo off
REM RimeBak Windows 快速引导 (Git Bash / WSL)

setlocal

REM 尝试定位 git bash
for %%B in ("C:\Program Files\Git\bin\bash.exe" "C:\Program Files\Git\usr\bin\bash.exe" "C:\Program Files (x86)\Git\bin\bash.exe" "C:\Program Files (x86)\Git\usr\bin\bash.exe" "bash.exe") do (
    if exist %%B set BASH_PATH=%%B
)

if not defined BASH_PATH (
    echo 未找到 bash.exe，請先安裝 Git Bash 或 WSL
    exit /b 1
)

REM 定位 onboarding 脚本
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%
set ONBOARDING=%PROJECT_DIR%scripts\rimebak_onboarding.sh

if not exist "%ONBOARDING%" (
    echo 未找到 %ONBOARDING%
    exit /b 1
)

"%BASH_PATH%" "%ONBOARDING%"
endlocal
