# dota-bot: installs this repository into Dota 2 as junctions (no admin rights, no copies to keep in sync):
#   <dota>\game\dota\scripts\vscripts\bots   -> <repo>\bots                 (bots for normal local games)
#   <dota>\game\dota_addons\dotabench         -> <repo>\tools\bench\addon    (the benchmark custom game)
#   <repo>\tools\bench\addon\scripts\vscripts\bots -> <repo>\bots           (its bots; git-ignored)
# The game then plays whatever branch is checked out here. Refuses to touch an existing folder it did not create.
#   pwsh tools/instalar.ps1 [-Dota "<path to dota 2 beta>"]
param([string]$Dota)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
if (-not $Dota) {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath
    $libraries = @($steam) + (Select-String -Path (Join-Path $steam 'steamapps\libraryfolders.vdf') -Pattern '"path"\s+"(.+)"' |
        ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' })
    $Dota = $libraries | ForEach-Object { Join-Path $_ 'steamapps\common\dota 2 beta' } | Where-Object { Test-Path $_ } |
        Select-Object -First 1
    if (-not $Dota) { throw 'Dota 2 not found in the Steam libraries; pass -Dota "<path to dota 2 beta>".' }
}

function Install-Junction([string]$Link, [string]$Target) {
    if (Test-Path $Link) {
        $item = Get-Item $Link -Force
        if ($item.LinkType -eq 'Junction' -and ($item.Target | Select-Object -First 1) -eq $Target) {
            Write-Output "already installed: $Link -> $Target"
        } else {
            throw "$Link already exists and is not this repository's junction; move it away by hand first."
        }
    } else {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
        Write-Output "installed: $Link -> $Target"
    }
}

$vscripts = Join-Path $Dota 'game\dota\scripts\vscripts'
Install-Junction (Join-Path $vscripts 'bots') (Join-Path $repo 'bots')

$addons = Join-Path $Dota 'game\dota_addons'
if (Test-Path $addons) {
    Install-Junction (Join-Path $repo 'tools\bench\addon\scripts\vscripts\bots') (Join-Path $repo 'bots')
    Install-Junction (Join-Path $addons 'dotabench') (Join-Path $repo 'tools\bench\addon')
} else {
    Write-Warning "No ${addons}: install the Dota 2 Workshop Tools DLC for the benchmark custom game."
}

$override = Join-Path $vscripts 'game\Customize'
if (Test-Path $override) { Write-Warning "$override exists and overrides bots\Customize (OHA reads it first)." }
