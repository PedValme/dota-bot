# dota-bot: installs this repository's bots into Dota 2 as a junction (no admin rights, no copy to keep in sync):
# <dota>\game\dota\scripts\vscripts\bots -> <repo>\bots.
# The game then plays whatever branch is checked out here. Refuses to touch an existing bots folder it did not create.
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

$vscripts = Join-Path $Dota 'game\dota\scripts\vscripts'
$link = Join-Path $vscripts 'bots'
$target = Join-Path $repo 'bots'
if (Test-Path $link) {
    $item = Get-Item $link -Force
    if ($item.LinkType -eq 'Junction' -and ($item.Target | Select-Object -First 1) -eq $target) {
        Write-Output "bots already installed: $link -> $target"
    } else {
        throw "$link already exists and is not this repository's junction; move it away by hand first."
    }
} else {
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Output "bots installed: $link -> $target"
}

$override = Join-Path $vscripts 'game\Customize'
if (Test-Path $override) { Write-Warning "$override exists and overrides bots\Customize (OHA reads it first)." }
