param(
    [string]$GameDataPath,
    [string]$SourceRoot
)

. (Join-Path $PSScriptRoot 'common.ps1')
if (-not $SourceRoot) { $SourceRoot = Get-SourceRoot }

Write-Host 'Shadow Warrior Windows 11 diagnostics'
Write-Host '===================================='
Write-Host "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host "64-bit OS: $([Environment]::Is64BitOperatingSystem)"
Write-Host "64-bit process: $([Environment]::Is64BitProcess)"
Write-Host "Source root: $SourceRoot"
Write-Host "Profile directory: $env:APPDATA\JFShadowWarrior"
Write-Host ''

$checks = [ordered]@{}
$checks['sw.exe'] = Test-Path (Join-Path $SourceRoot 'sw.exe')
$checks['Makefile.msvcuser'] = Test-Path (Join-Path $SourceRoot 'Makefile.msvcuser')
$checks['Win11 manifest'] = Test-Path (Join-Path $SourceRoot 'rsrc\game.manifest')
$checks['Portable marker absent'] = -not (Test-Path (Join-Path $SourceRoot 'user_profiles_disabled'))
$configSource = Join-Path $SourceRoot 'src\config.c'
$jfbuildSdl = Join-Path $SourceRoot 'jfbuild\src\sdlayer2.c'
$jfbuildBase = Join-Path $SourceRoot 'jfbuild\src\baselayer.c'
$checks['1080p source default'] = (Test-Path $configSource) -and [bool](Select-String -Path $configSource -SimpleMatch 'ScreenWidth = 1920' -Quiet)
$checks['Stage 3 display patch'] = (Test-Path $jfbuildSdl) -and [bool](Select-String -Path $jfbuildSdl -SimpleMatch 'SW_DISPLAY_MODE' -Quiet)
$checks['4K standard mode'] = (Test-Path $jfbuildBase) -and [bool](Select-String -Path $jfbuildBase -SimpleMatch '{3840,2160}' -Quiet)
if ($GameDataPath) { try { $data=(Resolve-Path $GameDataPath -ErrorAction Stop).Path; $checks['SW.GRP']=Test-Path (Join-Path $data 'SW.GRP') } catch { $checks['Game data directory']=$false } }
foreach ($entry in $checks.GetEnumerator()) { $state=if($entry.Value){'OK'}else{'MISSING/FAILED'}; Write-Host ("  {0,-28} {1}" -f $entry.Key,$state) }
try { Get-CimInstance Win32_VideoController | ForEach-Object { $mode=if($_.CurrentHorizontalResolution -and $_.CurrentVerticalResolution){"$($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate) Hz"}else{'current mode unavailable'}; Write-Host "  $($_.Name) | $mode | driver $($_.DriverVersion)" } } catch { Write-Host 'Could not query Win32_VideoController.' }
$failed=@($checks.GetEnumerator()|Where-Object{-not $_.Value});if($failed.Count -gt 0){Write-Warning "$($failed.Count) diagnostic check(s) need attention.";exit 1}
Write-Host 'Diagnostics completed successfully.'
