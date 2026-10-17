#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Copia para outra pasta (de preferência no HD externo) os arquivos que a planilha do
  script 04 marcou como "So no SSD antigo" ou "Antigo mais recente", mantendo a estrutura
  de pastas. Só lê a origem; não altera nada nela nem no disco em uso.

  Lembrete: no script 04, "SSD antigo" quer dizer o disco passado em -RaizAntigo.
  Na clonagem de out/2026, esse disco é o NVMe parado (E: e F:).

.PARAMETER Planilha
  CSV gerado pelo script 04.

.PARAMETER RaizOrigem
  A mesma raiz usada em -RaizAntigo no script 04 (ex.: F:\).

.PARAMETER Destino
  Pasta de destino (ex.: G:\Arquivos-NVMe\F).

.EXAMPLE
  .\05-guardar-arquivos-alterados.ps1 -Planilha C:\Suporte\alterados-nvme-F.csv -RaizOrigem F:\ -Destino G:\Arquivos-NVMe\F
#>
param(
    [Parameter(Mandatory = $true)][string]$Planilha,
    [Parameter(Mandatory = $true)][string]$RaizOrigem,
    [Parameter(Mandatory = $true)][string]$Destino
)

$ErrorActionPreference = "Stop"
$RaizOrigem = $RaizOrigem.TrimEnd('\') + '\'

$linhas = Import-Csv -Path $Planilha -Delimiter ';' -Encoding UTF8 |
    Where-Object { $_.Situacao -in "So no SSD antigo", "Antigo mais recente" }

$ok = 0; $falhas = @()
foreach ($l in $linhas) {
    $origem = Join-Path $RaizOrigem $l.Caminho
    $alvo   = Join-Path $Destino $l.Caminho
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $alvo) | Out-Null
        Copy-Item -LiteralPath $origem -Destination $alvo -Force
        (Get-Item -LiteralPath $alvo).LastWriteTime = (Get-Item -LiteralPath $origem).LastWriteTime
        $ok++
    } catch {
        $falhas += "$($l.Caminho): $($_.Exception.Message)"
    }
}

Write-Host "Copiados: $ok de $($linhas.Count) arquivos para $Destino" -ForegroundColor Green
if ($falhas) {
    $logFalhas = Join-Path $Destino "falhas.txt"
    $falhas | Set-Content -Path $logFalhas -Encoding UTF8
    Write-Host "Falhas: $($falhas.Count). Veja $logFalhas" -ForegroundColor Red
}
