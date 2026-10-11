#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Backup lógico (pg_dump) de todos os bancos do PostgreSQL que está rodando agora.
  Pode rodar com o sistema em uso: o pg_dump só lê e gera uma cópia consistente.

.PARAMETER Destino
  Pasta de destino, de preferência no HD externo (ex.: E:\Backup-Banco).

.PARAMETER PgBin
  (Opcional) Pasta "bin" do PostgreSQL. Se omitida, é descoberta pelo serviço do Windows.

.EXAMPLE
  .\02-backup-banco-atual.ps1 -Destino E:\Backup-Banco
#>
param(
    [Parameter(Mandatory = $true)][string]$Destino,
    [string]$PgBin,
    [string]$Usuario = "postgres",
    [int]$Porta = 5432
)

$ErrorActionPreference = "Stop"

if (-not $PgBin) {
    $svc = Get-CimInstance Win32_Service | Where-Object { $_.PathName -match "pg_ctl" } | Select-Object -First 1
    if (-not $svc) { throw "Servico do PostgreSQL nao encontrado. Informe -PgBin manualmente." }
    if ($svc.PathName -match '^"?(.+?\\bin)\\pg_ctl\.exe') { $PgBin = $Matches[1] }
    else { throw "Nao consegui ler a pasta bin em: $($svc.PathName). Informe -PgBin." }
}
$pgDump    = Join-Path $PgBin "pg_dump.exe"
$pgDumpAll = Join-Path $PgBin "pg_dumpall.exe"
$pgRestore = Join-Path $PgBin "pg_restore.exe"
$psql      = Join-Path $PgBin "psql.exe"
foreach ($exe in $pgDump, $pgDumpAll, $pgRestore, $psql) {
    if (-not (Test-Path $exe)) { throw "Nao encontrado: $exe" }
}

$carimbo = Get-Date -Format "yyyy-MM-dd_HHmm"
$pasta = Join-Path $Destino $carimbo
New-Item -ItemType Directory -Force -Path $pasta | Out-Null

$senha = Read-Host "Senha do usuario '$Usuario' do PostgreSQL" -AsSecureString
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))

try {
    $bancos = & $psql -h localhost -p $Porta -U $Usuario -d postgres -t -A -c `
        "SELECT datname FROM pg_database WHERE NOT datistemplate AND datname <> 'postgres' ORDER BY 1;"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao listar os bancos (senha ou porta incorreta?)." }
    $bancos = $bancos | Where-Object { $_.Trim() }
    Write-Host "Bancos encontrados: $($bancos -join ', ')"

    # Usuarios e permissoes (necessario para restaurar em outro servidor)
    & $pgDumpAll -h localhost -p $Porta -U $Usuario --globals-only -f (Join-Path $pasta "globais.sql")
    if ($LASTEXITCODE -ne 0) { throw "Falha no pg_dumpall --globals-only." }

    foreach ($b in $bancos) {
        $arquivo = Join-Path $pasta "$b.dump"
        Write-Host "Copiando banco '$b'..."
        & $pgDump -h localhost -p $Porta -U $Usuario -Fc -f $arquivo $b
        if ($LASTEXITCODE -ne 0) { throw "Falha no pg_dump do banco $b." }

        # Confere se o arquivo pode ser lido pelo pg_restore
        & $pgRestore -l $arquivo | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "O arquivo $arquivo nao passou na verificacao." }

        $mb = [math]::Round((Get-Item $arquivo).Length / 1MB, 1)
        Write-Host "  OK: $arquivo ($mb MB)" -ForegroundColor Green
    }
    Write-Host "`nBackup concluido em: $pasta" -ForegroundColor Green
}
finally {
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}
