#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Lista os arquivos do SSD ANTIGO alterados no período em que o servidor rodou por ele,
  e compara cada um com o mesmo caminho no disco atual. Só lê; não copia nada.

  Resultado: planilha CSV (abre no Excel) com a situação de cada arquivo:
    - "So no SSD antigo"     -> arquivo novo, não existe no disco atual
    - "Antigo mais recente"  -> existe nos dois, a versão do SSD antigo é mais nova
    - "Atual mais recente"   -> existe nos dois, o disco atual já tem versão mais nova (conflito: revisar)
    - "Iguais (mesma data)"  -> nada a fazer

.PARAMETER RaizAntigo
  Raiz do SSD antigo (ex.: F:\).

.PARAMETER Desde
  Data/hora da queda de energia (início do período no SSD antigo). Ex.: "2026-10-05 08:00".

.PARAMETER Ate
  (Opcional) Data/hora em que o SSD de 2 TB foi reativado. Padrão: agora.

.EXAMPLE
  .\04-arquivos-alterados.ps1 -RaizAntigo F:\ -Desde "2026-10-05 08:00" -Ate "2026-10-09 18:00"
#>
param(
    [Parameter(Mandatory = $true)][string]$RaizAntigo,
    [Parameter(Mandatory = $true)][datetime]$Desde,
    [datetime]$Ate = (Get-Date),
    [string]$RaizAtual = "$env:SystemDrive\",
    [string]$Saida = "C:\Suporte\arquivos-alterados-ssd-antigo.csv"
)

$RaizAntigo = $RaizAntigo.TrimEnd('\') + '\'
$RaizAtual  = $RaizAtual.TrimEnd('\') + '\'

# Pastas do sistema e temporários: geram ruído e não devem ser copiadas.
# A pasta de dados do PostgreSQL também fica de fora: o banco é tratado à parte (script 03),
# nunca copiado arquivo a arquivo.
$ignorar = '\\Windows\\|\\\$Recycle\.Bin\\|\\System Volume Information\\|\\ProgramData\\Microsoft\\|' +
           '\\AppData\\Local\\Temp\\|\\AppData\\Local\\Microsoft\\|\\AppData\\Local\\Google\\|' +
           '\\AppData\\Local\\Packages\\|\\pagefile\.sys$|\\hiberfil\.sys$|\\swapfile\.sys$|' +
           '\\PostgreSQL\\[^\\]+\\data\\'

Write-Host "Varrendo $RaizAntigo (alterados entre $Desde e $Ate)... pode demorar alguns minutos."
New-Item -ItemType Directory -Force -Path (Split-Path $Saida) | Out-Null

$resultado = Get-ChildItem -Path $RaizAntigo -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $Desde -and $_.LastWriteTime -le $Ate -and $_.FullName -notmatch $ignorar } |
    ForEach-Object {
        $relativo = $_.FullName.Substring($RaizAntigo.Length)
        $noAtual  = Join-Path $RaizAtual $relativo
        $atual    = Get-Item -LiteralPath $noAtual -Force -ErrorAction SilentlyContinue

        $alteradoAtual = $null
        if (-not $atual)                                       { $situacao = "So no SSD antigo" }
        else {
            $alteradoAtual = $atual.LastWriteTime
            if     ($_.LastWriteTime -gt $atual.LastWriteTime) { $situacao = "Antigo mais recente" }
            elseif ($_.LastWriteTime -lt $atual.LastWriteTime) { $situacao = "Atual mais recente" }
            else                                               { $situacao = "Iguais (mesma data)" }
        }

        [pscustomobject]@{
            Situacao        = $situacao
            Caminho         = $relativo
            AlteradoAntigo  = $_.LastWriteTime
            AlteradoAtual   = $alteradoAtual
            TamanhoKB       = [math]::Round($_.Length / 1KB, 1)
            Pasta           = Split-Path $relativo -Parent
        }
    }

$resultado | Sort-Object Situacao, Caminho |
    Export-Csv -Path $Saida -NoTypeInformation -Delimiter ';' -Encoding UTF8

Write-Host "`nResumo:"
$resultado | Group-Object Situacao | Sort-Object Name | Format-Table Name, Count -AutoSize
Write-Host "Pastas com mais alteracoes:"
$resultado | Group-Object Pasta | Sort-Object Count -Descending | Select-Object -First 15 | Format-Table Count, Name -AutoSize
Write-Host "Planilha salva em: $Saida" -ForegroundColor Green
