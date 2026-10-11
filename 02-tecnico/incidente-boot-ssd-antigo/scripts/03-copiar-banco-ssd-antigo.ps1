#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Copia a pasta de dados do PostgreSQL que está no SSD ANTIGO, sem iniciar o banco
  e sem alterar nada na origem. A cópia guarda os lançamentos feitos no período em
  que o servidor rodou pelo SSD antigo.

.PARAMETER Origem
  Pasta "data" do PostgreSQL no SSD antigo. Mesmo caminho do serviço, trocando a letra
  (ex.: F:\Program Files\PostgreSQL\10\data).

.PARAMETER Destino
  Pasta de destino, de preferência no HD externo (ex.: E:\Banco-SSD-Antigo).

.EXAMPLE
  .\03-copiar-banco-ssd-antigo.ps1 -Origem "F:\Program Files\PostgreSQL\10\data" -Destino E:\Banco-SSD-Antigo
#>
param(
    [Parameter(Mandatory = $true)][string]$Origem,
    [Parameter(Mandatory = $true)][string]$Destino
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $Origem "PG_VERSION"))) {
    throw "Nao parece uma pasta de dados do PostgreSQL (PG_VERSION ausente): $Origem"
}
if ((Split-Path $Origem -Qualifier) -eq $env:SystemDrive) {
    throw "A origem esta no disco do sistema atual ($env:SystemDrive). Use a letra do SSD ANTIGO."
}

Write-Host "Versao do PostgreSQL na origem: $(Get-Content (Join-Path $Origem 'PG_VERSION'))"
if (Test-Path (Join-Path $Origem "postmaster.pid")) {
    Write-Host "Aviso: existe postmaster.pid na origem (o banco nao foi desligado de forma limpa)." -ForegroundColor Yellow
    Write-Host "       Normal neste caso. A copia e feita do mesmo jeito; o PostgreSQL faz a recuperacao ao subir a copia." -ForegroundColor Yellow
}

$carimbo = Get-Date -Format "yyyy-MM-dd_HHmm"
$alvo = Join-Path $Destino "data_$carimbo"
$log  = Join-Path $Destino "robocopy_$carimbo.log"
New-Item -ItemType Directory -Force -Path $alvo | Out-Null

# /E subpastas · /COPY:DAT dados+atributos+datas · /DCOPY:T datas das pastas · /R:1 /W:1 sem esperar em erro
robocopy "$Origem" "$alvo" /E /COPY:DAT /DCOPY:T /R:1 /W:1 /NP "/LOG:$log" | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Robocopy terminou com erro (codigo $LASTEXITCODE). Veja $log" }

$o = Get-ChildItem $Origem -Recurse -File -Force | Measure-Object Length -Sum
$d = Get-ChildItem $alvo   -Recurse -File -Force | Measure-Object Length -Sum
Write-Host ("Origem : {0} arquivos, {1:N1} MB" -f $o.Count, ($o.Sum / 1MB))
Write-Host ("Copia  : {0} arquivos, {1:N1} MB" -f $d.Count, ($d.Sum / 1MB))
if ($o.Count -ne $d.Count -or $o.Sum -ne $d.Sum) {
    Write-Host "ATENCAO: a copia difere da origem. Veja o log: $log" -ForegroundColor Red
} else {
    Write-Host "Copia conferida: $alvo" -ForegroundColor Green
}
