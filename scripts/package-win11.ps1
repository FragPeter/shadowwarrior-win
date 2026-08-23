param([string]$SourceRoot,[string]$OutputPath)
. (Join-Path $PSScriptRoot 'common.ps1')
$kitRoot=Get-KitRoot
if (-not $SourceRoot) { $SourceRoot=Get-SourceRoot }
if (-not $OutputPath) { $OutputPath=Join-Path $kitRoot 'ShadowWarrior-Win11-x64-engine.zip' }
$exe=Join-Path $SourceRoot 'sw.exe'; if (-not (Test-Path $exe)) { throw 'sw.exe was not found. Build the port first.' }
$stage=Join-Path $env:TEMP ('shadowwarrior-win11-package-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $stage | Out-Null
try { Copy-Item $exe $stage; foreach($name in @('GPL.TXT','releasenotes.html')){$path=Join-Path $SourceRoot $name;if(Test-Path $path){Copy-Item $path $stage}}; foreach($dll in @('xaudio2_9redist.dll','SDL2.dll')){$path=Join-Path $SourceRoot $dll;if(Test-Path $path){Copy-Item $path $stage}}; foreach($launcherFile in @('Start-ShadowWarrior.ps1','Start-ShadowWarrior.cmd','README-WINDOWS11.txt')){Copy-Item (Join-Path $kitRoot ('launcher\'+$launcherFile)) $stage}; 'Shadow Warrior game data is NOT included.' | Set-Content -Encoding UTF8 (Join-Path $stage 'GAME-DATA-NOT-INCLUDED.txt'); if(Test-Path $OutputPath){Remove-Item $OutputPath -Force}; Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $OutputPath -CompressionLevel Optimal } finally { Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue }
