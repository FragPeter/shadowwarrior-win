param(
    [string]$GameDataPath,
    [switch]$Portable,
    [ValidateSet('Config','Windowed','Fullscreen','Borderless')]
    [string]$DisplayMode = 'Borderless',
    [ValidateRange(-1,15)]
    [int]$Monitor = -1,
    [ValidateRange(-1,8)]
    [int]$VSync = 1,
    [ValidateRange(0,1000)]
    [int]$MaxRefresh = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$engineDir = $PSScriptRoot
$exe = Join-Path $engineDir 'sw.exe'

if (-not (Test-Path $exe)) {
    throw "sw.exe was not found in $engineDir"
}

if (-not $GameDataPath) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select the folder containing your legally obtained Shadow Warrior SW.GRP file.'
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }
    $GameDataPath = $dialog.SelectedPath
}

$data = (Resolve-Path $GameDataPath -ErrorAction Stop).Path
$grp = Join-Path $data 'SW.GRP'
if (-not (Test-Path $grp)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("SW.GRP was not found in:`n$data", 'Shadow Warrior Windows 11') | Out-Null
    exit 2
}

$marker = Join-Path $engineDir 'user_profiles_disabled'
if ($Portable) {
    if (-not (Test-Path $marker)) { New-Item -ItemType File -Path $marker | Out-Null }
} elseif (Test-Path $marker) {
    Remove-Item $marker -Force
}

$names = @('SWGRP','SW_DISPLAY_MODE','SW_MONITOR','SW_VSYNC','SW_MAX_REFRESH')
$old = @{}
foreach ($name in $names) { $old[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

$env:SWGRP = $grp
if ($DisplayMode -eq 'Config') { Remove-Item Env:SW_DISPLAY_MODE -ErrorAction SilentlyContinue } else { $env:SW_DISPLAY_MODE = $DisplayMode.ToLowerInvariant() }
if ($Monitor -ge 0) { $env:SW_MONITOR = [string]$Monitor } else { Remove-Item Env:SW_MONITOR -ErrorAction SilentlyContinue }
$env:SW_VSYNC = [string]$VSync
if ($MaxRefresh -gt 0) { $env:SW_MAX_REFRESH = [string]$MaxRefresh } else { Remove-Item Env:SW_MAX_REFRESH -ErrorAction SilentlyContinue }

$exitCode = 0
Push-Location $engineDir
try {
    & $exe
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
    foreach ($name in $names) {
        if ($null -eq $old[$name]) {
            Remove-Item ("Env:" + $name) -ErrorAction SilentlyContinue
        } else {
            [Environment]::SetEnvironmentVariable($name, $old[$name], 'Process')
        }
    }
}
exit $exitCode
