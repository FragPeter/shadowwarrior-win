param(
    [Parameter(Mandatory=$true)][string]$GameDataPath,
    [ValidateSet('Config','Windowed','Fullscreen','Borderless')][string]$DisplayMode = 'Borderless',
    [ValidateRange(-1,15)][int]$Monitor = -1,
    [ValidateRange(-1,8)][int]$VSync = 1,
    [ValidateRange(0,1000)][int]$MaxRefresh = 0,
    [switch]$Portable
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$engineDir = $PSScriptRoot
$exe = Join-Path $engineDir 'sw.exe'
if (-not (Test-Path $exe)) { throw "sw.exe was not found in $engineDir." }

$data = (Resolve-Path $GameDataPath -ErrorAction Stop).Path
$grp = Join-Path $data 'SW.GRP'
if (-not (Test-Path $grp)) { throw "SW.GRP was not found in $data." }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDir = Join-Path $engineDir ("runtime-test-" + $stamp)
New-Item -ItemType Directory -Path $reportDir | Out-Null

$stdoutPath = Join-Path $engineDir 'stdout.txt'
$stderrPath = Join-Path $engineDir 'stderr.txt'
Remove-Item $stdoutPath,$stderrPath -Force -ErrorAction SilentlyContinue

$marker = Join-Path $engineDir 'user_profiles_disabled'
if ($Portable) {
    if (-not (Test-Path $marker)) { New-Item -ItemType File -Path $marker | Out-Null }
} elseif (Test-Path $marker) {
    Remove-Item $marker -Force
}

$envNames = @('SWGRP','SW_DISPLAY_MODE','SW_MONITOR','SW_VSYNC','SW_MAX_REFRESH','BUILD_REDIR_STDIO')
$old = @{}
foreach ($name in $envNames) { $old[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }

$env:SWGRP = $grp
if ($DisplayMode -eq 'Config') { Remove-Item Env:SW_DISPLAY_MODE -ErrorAction SilentlyContinue }
else { $env:SW_DISPLAY_MODE = $DisplayMode.ToLowerInvariant() }
if ($Monitor -ge 0) { $env:SW_MONITOR = [string]$Monitor }
else { Remove-Item Env:SW_MONITOR -ErrorAction SilentlyContinue }
$env:SW_VSYNC = [string]$VSync
if ($MaxRefresh -gt 0) { $env:SW_MAX_REFRESH = [string]$MaxRefresh }
else { Remove-Item Env:SW_MAX_REFRESH -ErrorAction SilentlyContinue }
$env:BUILD_REDIR_STDIO = 'TRUE'

$start = Get-Date
$exitCode = $null
$launchError = $null

Write-Host ''
Write-Host 'Shadow Warrior Windows 11 runtime test'
Write-Host "Engine:       $exe"
Write-Host "Game data:    $grp"
Write-Host "Display mode: $DisplayMode"
Write-Host "Monitor:      $Monitor"
Write-Host "VSync:        $VSync"
Write-Host "Max refresh:  $MaxRefresh"
Write-Host "Portable:     $Portable"
Write-Host ''
Write-Host 'Play for a few minutes. Test menus, mouse, sound and one level, then exit the game normally.'
Write-Host 'The report will be written automatically after the game closes.'
Write-Host ''

Push-Location $engineDir
try {
    try {
        $process = Start-Process -FilePath $exe -PassThru
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    } catch {
        $launchError = $_.Exception.Message
    }
} finally {
    Pop-Location
    foreach ($name in $envNames) {
        if ($null -eq $old[$name]) { Remove-Item ('Env:' + $name) -ErrorAction SilentlyContinue }
        else { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
    }
}

$end = Get-Date
$duration = $end - $start

if (Test-Path $stdoutPath) { Copy-Item $stdoutPath (Join-Path $reportDir 'stdout.txt') -Force }
if (Test-Path $stderrPath) { Copy-Item $stderrPath (Join-Path $reportDir 'stderr.txt') -Force }

$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
$gpuText = if ($gpus) { ($gpus | ForEach-Object { "$($_.Name) | Driver $($_.DriverVersion) | $($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate) Hz" }) -join "`r`n" } else { 'Unavailable' }

$profilePath = Join-Path $env:APPDATA 'JFShadowWarrior'
$status = if ($launchError) { 'LAUNCH FAILED' } elseif ($exitCode -eq 0) { 'EXITED NORMALLY' } else { "EXITED WITH CODE $exitCode" }

$report = @"
Shadow Warrior Windows 11 Runtime Test
======================================
Status:        $status
Started:       $($start.ToString('o'))
Ended:         $($end.ToString('o'))
Runtime:       $([math]::Round($duration.TotalSeconds,1)) seconds
Exit code:     $exitCode
Launch error:  $launchError

Engine:        $exe
Game data:     $grp
Display mode:  $DisplayMode
Monitor:       $Monitor
VSync:         $VSync
Max refresh:   $MaxRefresh
Portable:      $Portable
Profile path:  $profilePath

OS:            $($os.Caption) $($os.Version) build $($os.BuildNumber)
64-bit OS:     $([Environment]::Is64BitOperatingSystem)
64-bit process:$([Environment]::Is64BitProcess)

GPU / display
-------------
$gpuText

Manual checks
-------------
[ ] Game reached main menu
[ ] Level started
[ ] Borderless/window/fullscreen looked correct
[ ] Alt+Tab worked
[ ] Mouse movement/aiming worked
[ ] Keyboard worked
[ ] Controller worked (if tested)
[ ] Sound effects worked
[ ] Music worked
[ ] Save/load worked
[ ] No obvious speed/timing problem
[ ] Game exited normally

Log files
---------
stdout.txt and stderr.txt are stored beside this report when produced by the engine.
"@

$reportPath = Join-Path $reportDir 'runtime-report.txt'
Set-Content -Path $reportPath -Value $report -Encoding utf8

Write-Host ''
Write-Host "Runtime test finished: $status"
Write-Host "Runtime: $([math]::Round($duration.TotalSeconds,1)) seconds"
Write-Host "Report:  $reportPath"
Write-Host ''

if ($launchError -or ($null -ne $exitCode -and $exitCode -ne 0)) { exit 1 }
exit 0
