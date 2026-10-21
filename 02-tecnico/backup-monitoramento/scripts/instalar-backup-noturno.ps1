#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Instala a rotina de backup noturno no servidor. Roda uma vez.

  1. Cria (ou atualiza a senha de) um usuario proprio de backup no PostgreSQL, com senha
     aleatoria. Para isso, libera por alguns segundos o acesso sem senha do dono dos bancos,
     so de dentro do servidor, e devolve o pg_hba.conf em seguida (mesmo se der erro).
  2. Deixa o usuario de backup aceito so de dentro do servidor (pg_hba.conf).
  3. Guarda a senha em C:\Suporte\backup\pgpass.conf, legivel so por SYSTEM e Administradores.
  4. Copia o backup-noturno.ps1 para C:\Suporte\backup e cria a tarefa agendada
     "Amparo - Backup noturno" (todo dia no horario escolhido, como SYSTEM).
  5. Testa a conexao com a senha guardada.

  No fim, mostra a senha UMA vez para ser guardada no cofre. Nao copiar a senha para chat
  nem para o repositorio.

  Nao mexe na senha do postgres nem na do dono dos bancos (sageuser), que o sistema da folha usa.

.PARAMETER NtfyTopico
  (Opcional) Topico do ntfy.sh para receber o resultado no celular. Use "auto" para gerar um
  nome aleatorio. Vazio: sem aviso no celular.

.EXAMPLE
  .\instalar-backup-noturno.ps1 -NtfyTopico auto
#>
param(
    [string]$PgBin      = "C:\PostgreSQL\10\bin",
    [string]$PgData     = "C:\PostgreSQL\10\data",
    [string]$Servico    = "postgresql-x64-10",
    [string]$DonoBanco  = "sageuser",
    [string]$Usuario    = "backup_amparo",
    [string]$Horario    = "23:00",
    [string]$Destino    = "G:\Backup-Noturno",
    [string]$NtfyTopico = ""
)

$ErrorActionPreference = "Stop"
$pasta    = "C:\Suporte\backup"
$passFile = Join-Path $pasta "pgpass.conf"
$scriptDestino = Join-Path $pasta "backup-noturno.ps1"
$hba      = Join-Path $PgData "pg_hba.conf"
$pgCtl    = Join-Path $PgBin "pg_ctl.exe"
$psql     = Join-Path $PgBin "psql.exe"

# ---------- Conferencias ----------
$origemScript = Join-Path $PSScriptRoot "backup-noturno.ps1"
if (-not (Test-Path $origemScript)) { throw "backup-noturno.ps1 precisa estar na mesma pasta deste instalador." }
foreach ($f in $hba, $pgCtl, $psql) { if (-not (Test-Path $f)) { throw "Nao encontrado: $f" } }
if ((Get-Service $Servico).Status -ne "Running") { throw "O servico $Servico nao esta rodando." }
if (-not (Test-Path ((Split-Path $Destino -Qualifier) + "\"))) { throw "HD externo $(Split-Path $Destino -Qualifier) nao encontrado." }

New-Item -ItemType Directory -Force -Path $pasta, (Join-Path $pasta "logs") | Out-Null

function Recarregar {
    & $pgCtl reload -D $PgData | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "pg_ctl reload falhou." }
    Start-Sleep -Seconds 2
}

# ---------- 1 e 2. Usuario de backup e pg_hba.conf ----------
$caracteres = [char[]]"ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"
$bytes = New-Object byte[] 24
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$senha = -join ($bytes | ForEach-Object { $caracteres[$_ % $caracteres.Length] })

$copiaHba = "$hba.antes-backup-" + (Get-Date -Format "yyyyMMdd_HHmm")
Copy-Item $hba $copiaHba
Write-Host "Copia do pg_hba.conf original: $copiaHba"

$original = @(Get-Content $copiaHba)
$regrasBackup = @(
    "# Usuario do backup noturno: so de dentro do servidor (instalar-backup-noturno.ps1)",
    "host all $Usuario 127.0.0.1/32 md5",
    "host all $Usuario ::1/128 md5",
    "host all $Usuario all reject"
)
if (@($original | Where-Object { $_ -match "^\s*host\s+all\s+$Usuario\s" }).Count -gt 0) {
    $final = $original                      # regras ja existem (instalacao repetida)
} else {
    $final = $regrasBackup + $original      # antes de "host all all all md5", que vale para o resto
}
$temporario = @("host all $DonoBanco 127.0.0.1/32 trust", "host all $DonoBanco ::1/128 trust") + $final

$sql = 'DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = ''{0}'') THEN ALTER ROLE {0} WITH LOGIN SUPERUSER PASSWORD ''{1}''; ELSE CREATE ROLE {0} WITH LOGIN SUPERUSER PASSWORD ''{1}''; END IF; END $$;' -f $Usuario, $senha

try {
    Set-Content -Path $hba -Value $temporario -Encoding ASCII   # ASCII: sem BOM
    Recarregar
    & $psql -h localhost -U $DonoBanco -d postgres -w -c $sql | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Nao foi possivel criar o usuario $Usuario." }
    Write-Host "Usuario $Usuario criado/atualizado no PostgreSQL." -ForegroundColor Green
}
finally {
    Set-Content -Path $hba -Value $final -Encoding ASCII         # tira o acesso sem senha
    Recarregar
    if (@(Select-String -Path $hba -Pattern "^\s*host.*\strust\s*$").Count -gt 0) {
        Write-Host "ATENCAO: ainda ha regra 'trust' no pg_hba.conf. Restaurar: $copiaHba" -ForegroundColor Red
    } else {
        Write-Host "pg_hba.conf sem acesso sem senha (conferido)."
    }
}

# ---------- 3. Senha guardada ----------
Set-Content -Path $passFile -Value "localhost:5432:*:${Usuario}:$senha" -Encoding ASCII
& icacls $passFile /inheritance:r /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null   # SYSTEM e Administradores
if ($LASTEXITCODE -ne 0) { throw "Nao foi possivel proteger $passFile." }

# ---------- 4. Script e tarefa agendada ----------
Copy-Item $origemScript $scriptDestino -Force
if (-not [System.Diagnostics.EventLog]::SourceExists("Backup Amparo")) {
    New-EventLog -LogName Application -Source "Backup Amparo"
}

if ($NtfyTopico -eq "auto") {
    $b = New-Object byte[] 8
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
    $NtfyTopico = "amparo-backup-" + (-join ($b | ForEach-Object { $_.ToString("x2") }))
}
$argumentos = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDestino`" -Destino `"$Destino`""
if ($NtfyTopico) { $argumentos += " -NtfyTopico $NtfyTopico" }

$acao      = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argumentos
$gatilho   = New-ScheduledTaskTrigger -Daily -At $Horario
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$config    = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
                 -ExecutionTimeLimit (New-TimeSpan -Hours 8) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "Amparo - Backup noturno" -Action $acao -Trigger $gatilho `
    -Principal $principal -Settings $config -Force | Out-Null
Write-Host "Tarefa 'Amparo - Backup noturno' criada: todo dia as $Horario." -ForegroundColor Green

# ---------- 5. Teste ----------
$env:PGPASSFILE = $passFile
$quem = & $psql -h localhost -U $Usuario -d postgres -w -t -A -c "select current_user"
Remove-Item Env:\PGPASSFILE
if ($LASTEXITCODE -eq 0 -and "$quem".Trim() -eq $Usuario) {
    Write-Host "Teste de conexao com a senha guardada: OK" -ForegroundColor Green
} else {
    Write-Host "Teste de conexao FALHOU: $quem" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host " Senha do usuario $Usuario (guardar no cofre e fechar a janela):"   -ForegroundColor Yellow
Write-Host "   $senha"
if ($NtfyTopico) {
    Write-Host " Aviso no celular: instalar o app ntfy e assinar o topico:"     -ForegroundColor Yellow
    Write-Host "   $NtfyTopico"
}
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "Para rodar agora: Start-ScheduledTask 'Amparo - Backup noturno'"
