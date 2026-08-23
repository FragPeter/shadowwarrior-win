Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Get-VisualStudioInstallPath { $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'; if (-not (Test-Path $vswhere)) { throw 'Visual Studio Installer / vswhere.exe was not found. Install Visual Studio 2022 with Desktop development with C++.' }; $path=& $vswhere -latest -products * -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath; if (-not $path) { throw 'Visual Studio 2022 C++ tools were not found.' }; return $path.Trim() }
function Get-VcVars64 { $vs=Get-VisualStudioInstallPath; $vcvars=Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'; if (-not (Test-Path $vcvars)) { throw "vcvars64.bat was not found at $vcvars" }; return $vcvars }
function Invoke-VcCommand([Parameter(Mandatory=$true)][string]$Command) { $vcvars=Get-VcVars64; $cmdLine='call "'+$vcvars+'" >nul && '+$Command; & cmd.exe /d /s /c $cmdLine; if ($LASTEXITCODE -ne 0) { throw "MSVC command failed with exit code $LASTEXITCODE: $Command" } }
function Get-KitRoot { return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
function Get-SourceRoot { return (Join-Path (Split-Path (Get-KitRoot) -Parent) 'jfsw-win11') }
