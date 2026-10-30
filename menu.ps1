# menu.ps1 - Galaxy login menu
$ErrorActionPreference = "Stop"
$esc   = [char]27
$reset = "$esc[0m"

$dataDir   = Join-Path $env:APPDATA "GalaxyMenu"
$usersFile = Join-Path $dataDir "users.json"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir | Out-Null }

function Get-Hash([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace("-","").ToLower()
}

function Load-Users {
    if (Test-Path $usersFile) {
        $raw = Get-Content $usersFile -Raw
        if ($raw) {
            $obj = $raw | ConvertFrom-Json
            $h = @{}
            foreach ($p in $obj.PSObject.Properties) {
                $h[$p.Name] = @{ hash = $p.Value.hash; created = $p.Value.created }
            }
            return $h
        }
    }
    return @{}
}

function Save-Users($u) {
    $u | ConvertTo-Json -Depth 5 | Set-Content $usersFile -Encoding UTF8
}

function Show-Galaxy {
    param([string]$Subtitle = "")
    $w = 76
    $lines = New-Object 'System.Collections.Generic.List[object]'
    for ($y = 0; $y -lt 18; $y++) {
        $chars = New-Object char[] $w
        for ($i = 0; $i -lt $w; $i++) { $chars[$i] = ' ' }
        $lines.Add($chars)
    }
    $glyphs = @('.','*','+','·','✦','✧','⋆')
    for ($i = 0; $i -lt 90; $i++) {
        $x = Get-Random -Max $w
        $y = Get-Random -Max 18
        $lines[$y][$x] = ($glyphs | Get-Random)
    }
    $palette = @("$esc[95m","$esc[35m","$esc[94m","$esc[34m","$esc[96m","$esc[36m","$esc[97m")
    Write-Host ""
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $c = $palette[$i % $palette.Count]
        Write-Host "$c$(-join $lines[$i])$reset"
    }
    $title = "GALAXY"
    $pad   = [math]::Max(0, [int](($w - $title.Length) / 2))
    Write-Host ""
    Write-Host (" " * $pad) -NoNewline
    Write-Host "$esc[1;96m$title$reset"
    if ($Subtitle) {
        $pad2 = [math]::Max(0, [int](($w - $Subtitle.Length) / 2))
        Write-Host (" " * $pad2) -NoNewline
        Write-Host "$esc[90m$Subtitle$reset"
    }
    Write-Host ""
}

function Read-Password([string]$Prompt) {
    $sec = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try   { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Register {
    Clear-Host
    Show-Galaxy "Registreren"
    $u = Read-Host "Gebruikersnaam"
    if ([string]::IsNullOrWhiteSpace($u)) { Write-Host "Ongeldig." -ForegroundColor Red; Start-Sleep 1; return }
    $users = Load-Users
    if ($users.ContainsKey($u)) { Write-Host "Bestaat al." -ForegroundColor Red; Start-Sleep 1; return }
    $p1 = Read-Password "Wachtwoord"
    if ([string]::IsNullOrWhiteSpace($p1)) { Write-Host "Ongeldig." -ForegroundColor Red; Start-Sleep 1; return }
    $p2 = Read-Password "Herhaal wachtwoord"
    if ($p1 -ne $p2) { Write-Host "Wachtwoorden verschillen." -ForegroundColor Red; Start-Sleep 1; return }
    $users[$u] = @{ hash = (Get-Hash $p1); created = (Get-Date).ToString("o") }
    Save-Users $users
    Write-Host "Account '$u' aangemaakt. Druk Enter..." -ForegroundColor Green
    [void](Read-Host)
}

function Login {
    Clear-Host
    Show-Galaxy "Inloggen"
    $u = Read-Host "Gebruikersnaam"
    if ([string]::IsNullOrWhiteSpace($u)) { return $null }
    $p = Read-Password "Wachtwoord"
    $users = Load-Users
    if (-not $users.ContainsKey($u)) { Write-Host "Onbekende gebruiker." -ForegroundColor Red; Start-Sleep 1; return $null }
    if ($users[$u].hash -ne (Get-Hash $p)) { Write-Host "Onjuist wachtwoord." -ForegroundColor Red; Start-Sleep 1; return $null }
    return $u
}

function Main-Menu($user) {
    do {
        Clear-Host
        Show-Galaxy "Ingelogd als $user"
        Write-Host "  [$esc[96m1$reset] Menu-item 1"
        Write-Host "  [$esc[96m2$reset] Menu-item 2"
        Write-Host "  [$esc[96m3$reset] Menu-item 3"
        Write-Host "  [$esc[96mQ$reset] Uitloggen"
        Write-Host ""
        $k = Read-Host "Keuze"
        switch ($k.ToUpper()) {
            "1" { Write-Host "Item 1 uitgevoerd."; Start-Sleep 1 }
            "2" { Write-Host "Item 2 uitgevoerd."; Start-Sleep 1 }
            "3" { Write-Host "Item 3 uitgevoerd."; Start-Sleep 1 }
            "Q" { }
            default { Write-Host "Ongeldig." -ForegroundColor Red; Start-Sleep 1 }
        }
    } while ($k.ToUpper() -ne "Q")
}

# ---- Hoofdloop ----
:main while ($true) {
    Clear-Host
    Show-Galaxy "Welkom"
    Write-Host "  [$esc[96m1$reset] Inloggen"
    Write-Host "  [$esc[96m2$reset] Registreren"
    Write-Host "  [$esc[96mQ$reset] Stoppen"
    Write-Host ""
    $k = Read-Host "Keuze"
    switch ($k.ToUpper()) {
        "1" { $u = Login; if ($u) { Main-Menu $u } }
        "2" { Register }
        "Q" { break main }
        default { }
    }
}
