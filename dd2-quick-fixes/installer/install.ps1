# Ballista Saver installer: finds Dragon's Dogma 2 and copies the script to reframework\autorun.
$ErrorActionPreference = 'Stop'
try {
    $src = Join-Path $PSScriptRoot 'BallistaSaver.lua'
    if (-not (Test-Path $src)) { throw "BallistaSaver.lua must be in the same folder as this installer. Extract the whole zip first." }

    # Steam library folders
    $libs = @()
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if ($steam) {
        $libs += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in (Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"')) {
                $libs += ($m.Matches[0].Groups[1].Value -replace '\\\\', '\')
            }
        }
    }

    # find the folder that holds DD2.exe
    $game = $null
    foreach ($l in ($libs | Select-Object -Unique)) {
        $common = Join-Path $l 'steamapps\common'
        if (Test-Path $common) {
            foreach ($d in (Get-ChildItem $common -Directory -ErrorAction SilentlyContinue)) {
                if (Test-Path (Join-Path $d.FullName 'DD2.exe')) { $game = $d.FullName }
            }
        }
    }

    if (-not $game) {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = "Couldn't find Dragon's Dogma 2 automatically. Pick the folder that contains DD2.exe."
        if ($dlg.ShowDialog() -ne 'OK') { throw "Cancelled." }
        $game = $dlg.SelectedPath
        if (-not (Test-Path (Join-Path $game 'DD2.exe'))) { throw "That folder has no DD2.exe in it: $game" }
    }

    Write-Host "Game folder: $game"
    if (-not (Test-Path (Join-Path $game 'dinput8.dll'))) {
        Write-Host "WARNING: REFramework (dinput8.dll) is not in the game folder. Install REFramework first, or the script won't run." -ForegroundColor Yellow
    }

    $dest = Join-Path $game 'reframework\autorun'
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $src $dest -Force
    Write-Host "Installed: $(Join-Path $dest 'BallistaSaver.lua')" -ForegroundColor Green
    Write-Host "If the game is running: Insert > ScriptRunner > Reset scripts. Then Script Generated UI > Ballista Saver."
}
catch {
    Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Red
}
Read-Host "Press Enter to close"
