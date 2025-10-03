param(
    [switch]$GlobalInstall
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

Write-Info "RimeBak Windows 引导"
Write-Info "----------------------------------------"

$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
    Write-Info "未找到 bash。请先安装：Git for Windows / WSL / Cygwin"
    exit 1
}

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$onboarding = Join-Path $projectDir "scripts/rimebak_onboarding.sh"

if (-not (Test-Path $onboarding)) {
    Write-Info "未找到 $onboarding"
    exit 1
}

$bashPath = $bash.Source
$args = @($onboarding)
if ($GlobalInstall) {
    $args += "--global"
}

Write-Info "调用: $bashPath $($args -join ' ')"
& $bashPath @args
