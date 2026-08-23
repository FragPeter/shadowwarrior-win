param(
    [string]$SourceRoot
)

. (Join-Path $PSScriptRoot 'common.ps1')

$kitRoot = Get-KitRoot
$upstreamCommit = 'befcdd01afe5151cac2f1dabf0a7256c42537284'
if (-not $SourceRoot) { $SourceRoot = Get-SourceRoot }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git was not found in PATH. Install Git for Windows first.'
}

$null = Get-VcVars64

function Apply-RepoPatch {
    param([Parameter(Mandatory=$true)][string]$Repository,[Parameter(Mandatory=$true)][string]$Patch,[Parameter(Mandatory=$true)][string]$Label)
    Push-Location $Repository
    try {
        & git apply --check $Patch 2>$null
        if ($LASTEXITCODE -eq 0) { & git apply $Patch; if ($LASTEXITCODE -ne 0) { throw "Could not apply $Label." }; Write-Host "Applied: $Label"; return }
        & git apply --reverse --check $Patch 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Host "Already applied: $Label"; return }
        throw "$Label does not match the pinned source tree. Start from a clean checkout or inspect local changes."
    } finally { Pop-Location }
}

if (-not (Test-Path $SourceRoot)) {
    & git clone https://github.com/jonof/jfsw.git $SourceRoot
    if ($LASTEXITCODE -ne 0) { throw 'git clone failed.' }
}

Push-Location $SourceRoot
try {
    & git checkout $upstreamCommit
    if ($LASTEXITCODE -ne 0) { throw "Could not checkout pinned upstream commit $upstreamCommit." }
    & git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw 'git submodule update failed.' }
} finally {
    Pop-Location
}

& (Join-Path $kitRoot 'scripts\apply-win11-source-transforms.ps1') -SourceRoot $SourceRoot

$jfbuildRoot = Join-Path $SourceRoot 'jfbuild'
if (-not (Test-Path $jfbuildRoot)) { throw 'The jfbuild submodule was not initialized.' }
Apply-RepoPatch $jfbuildRoot (Join-Path $kitRoot 'patches\0003-jfbuild-win11-display-modernization.patch') 'JFBuild Win11 display modernization'

Copy-Item (Join-Path $kitRoot 'overlay\Makefile.msvcuser') (Join-Path $SourceRoot 'Makefile.msvcuser') -Force
Copy-Item (Join-Path $kitRoot 'overlay\rsrc\game.manifest') (Join-Path $SourceRoot 'rsrc\game.manifest') -Force
Write-Host 'Windows 11 Stage 3.1 overlay applied.'
