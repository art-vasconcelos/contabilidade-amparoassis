#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Rotina noturna de backup do servidor. Roda pela tarefa agendada "Amparo - Backup noturno",
  criada pelo instalar-backup-noturno.ps1.

  1. pg_dump de todos os bancos do PostgreSQL (um arquivo por banco, conferido com pg_restore -l),
     numa pasta por dia em <Destino>\banco\AAAA-MM-DD.
  2. Copia das pastas de trabalho para <Destino>\arquivos (robocopy /E: arquivos novos e alterados
     sao copiados; o que for apagado no servidor continua guardado no backup).
  3. Limpeza dos backups de banco antigos (so quando o backup do dia deu certo).
  4. Resultado em C:\Suporte\backup\logs, em <Destino>\ultimo-resultado.txt, no log de eventos do
     Windows (origem "Backup Amparo") e, se configurado, aviso no celular pelo ntfy.

  A senha do usuario de backup fica em C:\Suporte\backup\pgpass.conf (so SYSTEM e Administradores
  leem). Nada de senha neste arquivo.

.EXAMPLE
  .\backup-noturno.ps1
  .\backup-noturno.ps1 -NtfyTopico amparo-backup-xxxxxxxx
#>
param(
    [string]$Destino      = "G:\Backup-Noturno",
    [string]$PgBin        = "C:\PostgreSQL\10\bin",
    [string]$Usuario      = "backup_amparo",
    [string]$PassFile     = "C:\Suporte\backup\pgpass.conf",
    [string[]]$Pastas     = @("D:\Empresas", "D:\Rede - Amparo", "C:\Folhamatic"),
    [int]$DiasDiarios     = 14,   # guarda todos os backups de banco dos ultimos 14 dias
    [int]$DiasSemanais    = 60,   # e os de domingo dos ultimos 60 dias
    [int]$MinLivreGB      = 50,
    [string]$NtfyTopico   = ""
)

$inicio = Get-Date
$dia    = $inicio.ToString("yyyy-MM-dd")
$logDir = "C:\Suporte\backup\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log    = Join-Path $logDir "backup-$dia.log"
$erros  = New-Object System.Collections.Generic.List[string]
$resumo = New-Object System.Collections.Generic.List[string]

function Log([string]$m) {
    $linha = "{0:HH:mm:ss} {1}" -f (Get-Date), $m
    Add-Content -Path $log -Value $linha
    Write-Host $linha
}

function Erro([string]$m) {
    $erros.Add($m)
    Log "ERRO: $m"
}

# Roda um programa (pg_dump, psql...) e devolve o codigo de saida; mensagens vao para o log.
function Executar([string]$exe, [string[]]$argumentos) {
    $saida = & $exe @argumentos 2>&1
    $codigo = $LASTEXITCODE
    foreach ($s in $saida) { $t = "$s".Trim(); if ($t) { Log "   $t" } }
    return $codigo
}

Log "===== Inicio do backup ($env:COMPUTERNAME)"

$raiz = Split-Path $Destino -Qualifier
if (-not (Test-Path "$raiz\")) {
    Erro "HD externo ($raiz) nao encontrado. Backup nao foi feito."
}
else {
    $env:PGPASSFILE = $PassFile

    # ---------- 1. Banco ----------
    $pastaBanco = Join-Path $Destino "banco\$dia"
    New-Item -ItemType Directory -Force -Path $pastaBanco | Out-Null

    $r = & "$PgBin\psql.exe" -h localhost -U $Usuario -d postgres -w -t -A `
            -c "SELECT datname FROM pg_database WHERE NOT datistemplate AND datname <> 'postgres' ORDER BY 1" 2>&1
    $codigo = $LASTEXITCODE
    $bancos = @($r | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
                ForEach-Object { "$_".Trim() } | Where-Object { $_ })

    if ($codigo -ne 0 -or $bancos.Count -eq 0) {
        $r | ForEach-Object { Log "   $_" }
        Erro "Nao foi possivel conectar ao PostgreSQL com o usuario $Usuario (servico parado ou senha?)."
    }
    else {
        Log "Bancos: $($bancos -join ', ')"
        if ((Executar "$PgBin\pg_dumpall.exe" @("-h", "localhost", "-U", $Usuario, "-w", "--globals-only",
                                                 "-f", (Join-Path $pastaBanco "globais.sql"))) -ne 0) {
            Erro "Falha no pg_dumpall (usuarios e permissoes)."
        }
        foreach ($b in $bancos) {
            $t0 = Get-Date
            $arquivo = Join-Path $pastaBanco "$b.dump"
            if ((Executar "$PgBin\pg_dump.exe" @("-h", "localhost", "-U", $Usuario, "-w", "-Fc", "-f", $arquivo, $b)) -ne 0) {
                Erro "Falha no pg_dump do banco $b."
                continue
            }
            if ((Executar "$PgBin\pg_restore.exe" @("-l", $arquivo)) -ne 0) {
                Erro "O arquivo do banco $b nao passou na conferencia (pg_restore -l)."
                continue
            }
            $mb  = [math]::Round((Get-Item $arquivo).Length / 1MB, 1)
            $min = [math]::Round(((Get-Date) - $t0).TotalMinutes, 1)
            Log "OK banco $b ($mb MB, $min min)"
            $resumo.Add("$b $mb MB")
        }
    }

    # ---------- 2. Pastas ----------
    $logRobo = Join-Path $logDir "robocopy-$dia.log"
    foreach ($p in $Pastas) {
        if (-not (Test-Path $p)) { Erro "Pasta de origem nao encontrada: $p"; continue }
        $alvo = Join-Path $Destino ("arquivos\" + (Split-Path $p -Leaf))
        Log "Copiando $p -> $alvo"
        # /E subpastas · /COPY:DAT /DCOPY:T dados, atributos e datas · /XJ ignora atalhos de pasta
        # /R:1 /W:1 nao fica preso em arquivo travado · /MT:8 oito copias em paralelo
        robocopy "$p" "$alvo" /E /COPY:DAT /DCOPY:T /XJ /R:1 /W:1 /MT:8 /NP /NFL /NDL "/LOG+:$logRobo" | Out-Null
        $rc = $LASTEXITCODE
        if ($rc -ge 8) { Erro "Robocopy de $p terminou com erro (codigo $rc). Veja $logRobo" }
        else           { Log "OK pasta $p (codigo robocopy $rc)"; $resumo.Add("$(Split-Path $p -Leaf) ok") }
    }

    # ---------- 3. Limpeza (so com o backup do dia completo) ----------
    if ($erros.Count -eq 0) {
        Get-ChildItem (Join-Path $Destino "banco") -Directory | ForEach-Object {
            $d = [datetime]::MinValue
            if ([datetime]::TryParseExact($_.Name, "yyyy-MM-dd", $null, [Globalization.DateTimeStyles]::None, [ref]$d)) {
                $idade  = ($inicio.Date - $d).Days
                $manter = ($idade -le $DiasDiarios) -or ($d.DayOfWeek -eq [DayOfWeek]::Sunday -and $idade -le $DiasSemanais)
                if (-not $manter) {
                    Remove-Item $_.FullName -Recurse -Force
                    Log "Removido backup antigo do banco: $($_.Name)"
                }
            }
        }
        Get-ChildItem $logDir -File | Where-Object { $_.LastWriteTime -lt $inicio.AddDays(-90) } | Remove-Item -Force
    }
    else {
        Log "Limpeza nao feita porque houve erro hoje."
    }

    $livreGB = [math]::Round((New-Object System.IO.DriveInfo($raiz)).AvailableFreeSpace / 1GB)
    Log "Espaco livre no HD externo: $livreGB GB"
    if ($livreGB -lt $MinLivreGB) { Erro "Pouco espaco no HD externo: $livreGB GB livres." }
}

# ---------- 4. Resultado ----------
$duracao = [math]::Round(((Get-Date) - $inicio).TotalMinutes)
if ($erros.Count -eq 0) {
    $status = "OK"
    $msg = "Backup OK em $duracao min. " + ($resumo -join "; ") + ". Livre no HD: $livreGB GB."
}
else {
    $status = "FALHA"
    $msg = "Backup com FALHA ($($erros.Count) erro(s)): " + ($erros -join " | ")
}
Log "===== $status - $msg"

$textoResultado = "{0:dd/MM/yyyy HH:mm} {1}`r`n{2}`r`nLog: {3}" -f (Get-Date), $status, $msg, $log
Set-Content -Path "C:\Suporte\backup\ultimo-resultado.txt" -Value $textoResultado
if (Test-Path "$raiz\") { Set-Content -Path (Join-Path $Destino "ultimo-resultado.txt") -Value $textoResultado -ErrorAction SilentlyContinue }

try {
    $tipo = if ($status -eq "OK") { "Information" } else { "Error" }
    $id   = if ($status -eq "OK") { 1000 } else { 1001 }
    Write-EventLog -LogName Application -Source "Backup Amparo" -EventId $id -EntryType $tipo -Message $msg
} catch { Log "Nao gravou no log de eventos: $($_.Exception.Message)" }

if ($NtfyTopico) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $prioridade = if ($status -eq "OK") { "default" } else { "urgent" }
        Invoke-RestMethod -Method Post -Uri "https://ntfy.sh/$NtfyTopico" -Body ([Text.Encoding]::UTF8.GetBytes($msg)) `
            -Headers @{ Title = "Servidor Amparo - backup $status"; Priority = $prioridade } | Out-Null
    } catch { Log "Aviso pelo ntfy nao enviado: $($_.Exception.Message)" }
}

if ($status -ne "OK") { exit 1 }
