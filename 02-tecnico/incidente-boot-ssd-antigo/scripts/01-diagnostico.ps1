#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Diagnóstico dos discos, da ordem de boot e do PostgreSQL do servidor.
  Só lê informações; não altera nada.

.PARAMETER LetraSsdAntigo
  (Opcional) Letra do SSD antigo, se ele já estiver online com letra atribuída (ex.: F).
  Quando informada, lê o log de eventos do Windows do SSD antigo para descobrir
  em que período ele ficou ligado.

.EXAMPLE
  .\01-diagnostico.ps1
  .\01-diagnostico.ps1 -LetraSsdAntigo F
#>
param(
    [string]$LetraSsdAntigo
)

$pasta = "C:\Suporte"
New-Item -ItemType Directory -Force -Path $pasta | Out-Null
$saida = Join-Path $pasta ("diagnostico-" + (Get-Date -Format "yyyy-MM-dd_HHmm") + ".txt")

function Secao($titulo) { "`n==================== $titulo ====================" }

& {
    Secao "Computador"
    Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime | Format-List
    Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model | Format-List
    Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, ReleaseDate | Format-List

    Secao "Discos"
    Get-Disk | Sort-Object Number |
        Format-Table Number, FriendlyName, @{n="TamanhoGB";e={[math]::Round($_.Size/1GB)}},
                     OperationalStatus, IsBoot, IsSystem, IsReadOnly, PartitionStyle, Guid -AutoSize

    Secao "Saude fisica dos discos"
    Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus -AutoSize

    Secao "Particoes"
    Get-Partition | Sort-Object DiskNumber, PartitionNumber |
        Format-Table DiskNumber, PartitionNumber, DriveLetter, Type, @{n="TamanhoGB";e={[math]::Round($_.Size/1GB,1)}}, IsBoot, IsSystem -AutoSize

    Secao "Volumes (espaco usado)"
    Get-Volume | Where-Object DriveLetter |
        Format-Table DriveLetter, FileSystemLabel, FileSystem,
                     @{n="TamanhoGB";e={[math]::Round($_.Size/1GB,1)}},
                     @{n="UsadoGB";e={[math]::Round(($_.Size-$_.SizeRemaining)/1GB,1)}},
                     @{n="LivreGB";e={[math]::Round($_.SizeRemaining/1GB,1)}} -AutoSize

    Secao "Ordem de boot do firmware (UEFI)"
    bcdedit /enum firmware

    Secao "Gerenciador de boot do Windows"
    bcdedit /enum

    Secao "Servico do PostgreSQL"
    Get-CimInstance Win32_Service |
        Where-Object { $_.Name -match "postgres|pgsql" -or $_.PathName -match "pg_ctl" } |
        Select-Object Name, State, StartMode, PathName | Format-List

    Secao "Desligamentos inesperados registrados neste disco (eventos 41 e 6008)"
    Get-WinEvent -FilterHashtable @{ LogName = "System"; Id = 41, 6008 } -MaxEvents 20 -ErrorAction SilentlyContinue |
        Format-Table TimeCreated, Id, Message -Wrap

    Secao "Inicializacoes e desligamentos deste disco (eventos 6005 e 6006, ultimos 60 dias)"
    Get-WinEvent -FilterHashtable @{ LogName = "System"; Id = 6005, 6006; StartTime = (Get-Date).AddDays(-60) } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated | Format-Table TimeCreated, Id, @{n="Evento";e={ if ($_.Id -eq 6005) {"Windows iniciou"} else {"Windows desligou"} }} -AutoSize

    if ($LetraSsdAntigo) {
        $log = "$($LetraSsdAntigo.TrimEnd(':')):\Windows\System32\winevt\Logs\System.evtx"
        Secao "SSD ANTIGO - periodo em que ficou ligado (eventos 6005/6006/6008 de $log)"
        if (Test-Path $log) {
            Get-WinEvent -Path $log -ErrorAction SilentlyContinue |
                Where-Object { $_.Id -in 6005, 6006, 6008 -and $_.TimeCreated -gt (Get-Date).AddDays(-60) } |
                Sort-Object TimeCreated |
                Format-Table TimeCreated, Id, @{n="Evento";e={ switch ($_.Id) { 6005 {"Windows iniciou"} 6006 {"Windows desligou"} 6008 {"Desligamento inesperado anterior"} } }} -AutoSize
        } else {
            "Log nao encontrado em $log"
        }
    }
} *>&1 | Tee-Object -FilePath $saida

Write-Host "`nDiagnostico salvo em: $saida" -ForegroundColor Green
