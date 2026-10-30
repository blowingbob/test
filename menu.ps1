# menu.ps1 - eenvoudig scripted menu
$ErrorActionPreference = "Stop"

function Show-Menu {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "        HOOFDMENU" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "1) Systeeminformatie tonen"
    Write-Host "2) Schijfgebruik tonen"
    Write-Host "3) Actieve processen (top 10 op geheugen)"
    Write-Host "4) Notepad als administrator starten"
    Write-Host "5) System Informer starten"
    Write-Host "Q) Stoppen"
    Write-Host "==============================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $keuze = Read-Host "Maak een keuze"

    switch ($keuze.ToUpper()) {
        "1" {
            Get-ComputerInfo | Select-Object CsName, WindowsProductName, OsVersion, CsTotalPhysicalMemory
            Read-Host "Enter om terug te gaan"
        }
        "2" {
            Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n='UsedGB';e={[math]::Round($_.Used/1GB,2)}}, @{n='FreeGB';e={[math]::Round($_.Free/1GB,2)}}
            Read-Host "Enter om terug te gaan"
        }
        "3" {
            Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name, Id, @{n='RAM(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}
            Read-Host "Enter om terug te gaan"
        }
        "4" {
            Start-Process notepad.exe -Verb RunAs
            Read-Host "Notepad gestart. Enter om terug te gaan"
        }
        "5" {
            $si = "C:\Program Files\SystemInformer\SystemInformer.exe"
            if (Test-Path $si) {
                Start-Process $si -Verb RunAs
            } else {
                Write-Host "System Informer niet gevonden op $si" -ForegroundColor Red
            }
            Read-Host "Enter om terug te gaan"
        }
        "Q" {
            Write-Host "Stoppen..." -ForegroundColor Yellow
        }
        default {
            Write-Host "Ongeldige keuze." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($keuze.ToUpper() -ne "Q")
