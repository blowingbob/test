# menu.ps1 - Fullscreen galaxy login menu
Write-Host "VERSIE 2 - galaxy fullscreen" -ForegroundColor Yellow
Start-Sleep 1
$ErrorActionPreference = "Stop"
$esc   = [char]27
$reset = "$esc[0m"
$bgBlk = "$esc[40m"
$white = "$esc[37m"
$bright= "$esc[97m"

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

function Clear-Line([int]$row) {
    $w = [Console]::WindowWidth
    [Console]::SetCursorPosition(0, $row)
    Write-Host "$bgBlk$white$(' ' * ($w - 1))$reset" -NoNewline
}

function Clear-InputArea {
    $H = [Console]::WindowHeight
    for ($y = $H - 3; $y -lt $H; $y++) { Clear-Line $y }
}

function Draw-Galaxy {
    param([string[]]$MenuLines, [string]$Subtitle = "")

    $w = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    if ($H -lt 14) { $H = 24 }
    if ($w -lt 40) { $w = 80 }
    $inputRows = 3
    $starRows = $H - $inputRows

    [Console]::CursorVisible = $false
    [Console]::SetCursorPosition(0,0)

    $sb = New-Object System.Text.StringBuilder
    for ($y = 0; $y -lt $starRows; $y++) {
        $line = New-Object char[] ($w - 1)
        for ($i = 0; $i -lt ($w - 1); $i++) { $line[$i] = ' ' }
        $n = [math]::Max(2, [int]($w * 0.03))
        for ($s = 0; $s -lt $n; $s++) {
            $r = Get-Random -Max 10
            $ch = if ($r -lt 6) { '.' } elseif ($r -lt 9) { '*' } else { '+' }
            $line[(Get-Random -Max ($w - 1))] = $ch
        }
        [void]$sb.Append("$bgBlk$white$(-join $line)$reset`n")
    }
    Write-Host $sb.ToString() -NoNewline

    for ($y = $starRows; $y -lt $H; $y++) { Clear-Line $y }

    $allLines = @()
    if ($Subtitle) { $allLines += ""; $allLines += $Subtitle; $allLines += "" }
    $allLines += $MenuLines

    $startY = [math]::Max(1, [int](($starRows - $allLines.Count) / 2))

    $idx = 0
    foreach ($line in $allLines) {
        $y = $startY + $idx
        if ($y -ge 0 -and $y -lt $starRows) {
            $pad = [math]::Max(0, [int](($w - $line.Length) / 2))
            [Console]::SetCursorPosition($pad, $y)
            Write-Host "$bgBlk$bright$line$reset" -NoNewline
        }
        $idx++
    }
}

function Read-Password([string]$Prompt) {
    $sec = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try   { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Prompt([string]$Message) {
    $H = [Console]::WindowHeight
    Clear-InputArea
    [Console]::CursorVisible = $true
    [Console]::SetCursorPosition(2, $H - 2)
    $r = Read-Host $Message
    [Console]::CursorVisible = $false
    return $r
}

function Prompt-Password([string]$Message) {
    $H = [Console]::WindowHeight
    Clear-InputArea
    [Console]::CursorVisible = $true
    [Console]::SetCursorPosition(2, $H - 2)
    $r = Read-Password $Message
    [Console]::CursorVisible = $false
    return $r
}

function Register {
    Draw-Galaxy -MenuLines @("--- Registreren ---") -Subtitle ""
    $u = Prompt "Nieuwe gebruikersnaam"
    if ([string]::IsNullOrWhiteSpace($u)) { return }
    $users = Load-Users
    if ($users.ContainsKey($u)) {
        Clear-InputArea
        [Console]::SetCursorPosition(2, [Console]::WindowHeight - 2)
        Write-Host "Bestaat al." -ForegroundColor Red
        Start-Sleep 1; return
    }
    $p1 = Prompt-Password "Wachtwoord"
    if ([string]::IsNullOrWhiteSpace($p1)) { return }
    $p2 = Prompt-Password "Herhaal wachtwoord"
    if ($p1 -ne $p2) {
        Clear-InputArea
        [Console]::SetCursorPosition(2, [Console]::WindowHeight - 2)
        Write-Host "Wachtwoorden verschillen." -ForegroundColor Red
        Start-Sleep 1; return
    }
    $users[$u] = @{ hash = (Get-Hash $p1); created = (Get-Date).ToString("o") }
    Save-Users $users
    Clear-InputArea
    [Console]::SetCursorPosition(2, [Console]::WindowHeight - 2)
    Write-Host "Account '$u' aangemaakt." -ForegroundColor Green
    Start-Sleep 1
}

function Login {
    Draw-Galaxy -MenuLines @("--- Inloggen ---") -Subtitle ""
    $u = Prompt "Gebruikersnaam"
    if ([string]::IsNullOrWhiteSpace($u)) { return $null }
    $p = Prompt-Password "Wachtwoord"
    $users = Load-Users
    if (-not $users.ContainsKey($u) -or $users[$u].hash -ne (Get-Hash $p)) {
        Clear-InputArea
        [Console]::SetCursorPosition(2, [Console]::WindowHeight - 2)
        Write-Host "Onjuiste gegevens." -ForegroundColor Red
        Start-Sleep 1; return $null
    }
    return $u
}

function Main-Menu($user) {
    do {
        Draw-Galaxy -MenuLines @(
            "[1] Menu-item 1",
            "[2] Menu-item 2",
            "[3] Menu-item 3",
            "[Q] Uitloggen"
        ) -Subtitle "Ingelogd als $user"
        $k = Prompt "Keuze"
        switch ($k.ToUpper()) {
            "1" { }
            "2" { }
            "3" { }
            "Q" { }
        }
    } while ($k.ToUpper() -ne "Q")
}

:main while ($true) {
    Draw-Galaxy -MenuLines @(
        "[1] Inloggen",
        "[2] Registreren",
        "[Q] Stoppen"
    )
    $k = Prompt "Keuze"
    switch ($k.ToUpper()) {
        "1" { $u = Login; if ($u) { Main-Menu $u } }
        "2" { Register }
        "Q" { break main }
    }
}
