<#
.SYNOPSIS
  使用 ps2exe 将 PowerShell 引导脚本打包为 .exe，方便 Windows 用户双击运行。

.REQUIREMENTS
  - Windows PowerShell 5.1 或 PowerShell 7+
  - 已安装 ps2exe 模块（Install-Module ps2exe）
  - Git Bash / WSL / Cygwin 中之一用于实际执行 Bash 引导脚本

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\build-onboarding-exe.ps1

  生成的 RimeBakOnboarding.exe 位于项目根目录，可直接发送给用户。
#>

param(
    [string]$Output = "RimeBakOnboarding.exe"
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

if (-not (Get-Command ps2exe.ps1 -ErrorAction SilentlyContinue)) {
    Write-Info "未找到 ps2exe。请执行：Install-Module ps2exe"
    exit 1
}

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$psSource   = Join-Path $scriptDir "rimebak_onboarding.ps1"

if (-not (Test-Path $psSource)) {
    Write-Info "未找到 $psSource"
    exit 1
}

Write-Info "使用 ps2exe 打包 $psSource -> $Output"
& ps2exe.ps1 $psSource (Join-Path $projectDir $Output) -noConsole -icon None
Write-Info "完成：$(Join-Path $projectDir $Output)"
