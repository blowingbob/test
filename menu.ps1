function Show-Menu {
    Clear-Host
    Write-Host "==== MENU ====" -ForegroundColor Cyan
    Write-Host "1) Systeeminfo"
    Write-Host "2) Schijven"
    Write-Host "3) Top 10 processen"
    Write-Host "4) Notepad als admin"
    Write-Host "5) System Informer"
    Write-Host "Q) Stoppen"
}
do {
    Show-Menu
    $k = Read-Host "Keuze"
    switch ($k.ToUpper()) {
        "1" { Get-ComputerInfo | Select CsName, WindowsProductName, OsVersion; pause }
        "2" { Get-PSDrive -PSProvider FileSystem | Select Name, @{n='UsedGB';e={[math]::Round($_.Used/1GB,2)}}, @{n='FreeGB';e={[math]::Round($_.Free/1GB,2)}}; pause }
        "3" { Get-Process | Sort WorkingSet64 -Desc | Select -First 10 Name, Id, @{n='RAM(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}; pause }
        "4" { Start-Process notepad.exe -Verb RunAs; pause }
        "5" { $p="C:\Program Files\SystemInformer\SystemInformer.exe"; if (Test-Path $p) { Start-Process $p -Verb RunAs } else { Write-Host "Niet gevonden: $p" -ForegroundColor Red }; pause }
        "Q" { }
        default { Write-Host "Ongeldige keuze" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($k.ToUpper() -ne "Q")
