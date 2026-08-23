param([string]$SourceRoot,[switch]$Clean)
. (Join-Path $PSScriptRoot 'common.ps1')
if (-not $SourceRoot) { $SourceRoot = Get-SourceRoot }
if (-not (Test-Path (Join-Path $SourceRoot 'Makefile.msvc'))) { throw "JFShadowWarrior source was not found at $SourceRoot. Run bootstrap-win11.ps1 first." }
Push-Location $SourceRoot
try { if ($Clean) { Invoke-VcCommand 'nmake /nologo /f Makefile.msvc veryclean' }; Invoke-VcCommand 'nmake /nologo /f Makefile.msvc'; $exe=Join-Path $SourceRoot 'sw.exe'; if (-not (Test-Path $exe)) { throw 'Build completed without producing sw.exe.' }; Write-Host "Build complete: $exe" } finally { Pop-Location }
