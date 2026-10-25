#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Monitor de conexao: a cada 30 segundos testa, em ordem, cada trecho do caminho ate a internet
  e registra onde a conexao quebra. Serve para descobrir a causa das quedas de internet que
  "somem e voltam sozinhas".

  Trechos testados:
    Placa      cabo/placa de rede ligada
    Roteador   gateway da rede (ER605), descoberto automaticamente
    Operadora  equipamento logo depois do roteador (ONT/modem da operadora), descoberto por tracert
    Internet   dois enderecos publicos (Google e Cloudflare)
    DNS        resolucao de nomes pelo roteador e por um DNS publico

  Leitura da coluna "Situacao":
    OK                         tudo funcionando
    SEM CABO/PLACA             a placa desta maquina perdeu o link (cabo, porta do switch, energia do switch)
    SEM ROTEADOR               nao alcanca o ER605 (roteador reiniciando, sem energia, switch ou cabo)
    ROTEADOR SEM ONT           alcanca o ER605, mas nao a ONT (cabo ER605-ONT ou ONT reiniciando)
    OPERADORA SEM INTERNET     alcanca a ONT, mas nao a internet (problema da operadora)
    DNS DO ROTEADOR            internet ok, mas o DNS do ER605 nao resolve (DNS publico resolve)
    SEM DNS                    internet ok, mas nenhum DNS resolve

  Arquivos em C:\Suporte\rede:
    conexao-AAAA-MM-DD.csv     uma linha por teste (abre no Excel)
    eventos-AAAA-MM.log        so as mudancas de situacao, com a duracao de cada queda

.EXAMPLE
  .\monitor-conexao.ps1 -Instalar     # copia para C:\Suporte\rede e cria a tarefa que roda sempre
  .\monitor-conexao.ps1               # roda direto nesta janela (Ctrl+C para parar)
#>
param(
    [switch]$Instalar,
    [int]$Intervalo     = 30,
    [string]$Pasta      = "C:\Suporte\rede",
    [string[]]$Publicos = @("8.8.8.8", "1.1.1.1"),
    [string]$Site       = "google.com",
    [int]$DiasGuardar   = 60
)

New-Item -ItemType Directory -Force -Path $Pasta | Out-Null

if ($Instalar) {
    $destino = Join-Path $Pasta "monitor-conexao.ps1"
    if ($PSCommandPath -ne $destino) { Copy-Item $PSCommandPath $destino -Force }
    $acao      = New-ScheduledTaskAction -Execute "powershell.exe" `
                     -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$destino`""
    $gatilho   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $config    = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew `
                     -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
                     -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "Amparo - Monitor de conexao" -Action $acao -Trigger $gatilho `
        -Principal $principal -Settings $config -Force | Out-Null
    Start-ScheduledTask "Amparo - Monitor de conexao"
    Write-Host "Tarefa 'Amparo - Monitor de conexao' criada e iniciada. Registros em $Pasta" -ForegroundColor Green
    return
}

$pinger = New-Object System.Net.NetworkInformation.Ping

function Responde([string]$ip) {
    if (-not $ip) { return $null }
    try { return ($pinger.Send($ip, 1500).Status -eq [System.Net.NetworkInformation.IPStatus]::Success) }
    catch { return $false }
}

function Resolve([string]$servidor) {
    if (-not $servidor) { return $null }
    try { $null = Resolve-DnsName $Site -Server $servidor -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop; return $true }
    catch { return $false }
}

function Texto($v) { if ($null -eq $v) { "-" } elseif ($v) { "OK" } else { "FALHA" } }

function Evento([string]$m) {
    $arq = Join-Path $Pasta ("eventos-" + (Get-Date -Format "yyyy-MM") + ".log")
    Add-Content -Path $arq -Value ("{0:dd/MM/yyyy HH:mm:ss}  {1}" -f (Get-Date), $m)
}

# Equipamento logo depois do roteador (a ONT): segundo salto do tracert. Se ele nao responder a
# ping, o trecho "Operadora" fica fora dos testes para nao gerar alarme falso.
function DescobrirOperadora {
    try {
        $t = Test-NetConnection $Publicos[0] -TraceRoute -Hops 2 -WarningAction SilentlyContinue
        $salto = @($t.TraceRoute)[1]
        if ($salto -and $salto -ne "0.0.0.0" -and (Responde $salto)) { return $salto }
    } catch { }
    return $null
}

$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Evento ("Monitor iniciado em {0} (ultimo boot do Windows: {1:dd/MM/yyyy HH:mm:ss})" -f $env:COMPUTERNAME, $boot)

$operadora      = DescobrirOperadora
$ultimaBusca    = Get-Date
$situacaoAntes  = $null
$desde          = Get-Date

while ($true) {
    $inicio = Get-Date

    $rota    = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
    $gateway = if ($rota) { $rota.NextHop } else { $null }
    $placa   = if ($rota) { Get-NetAdapter -InterfaceIndex $rota.InterfaceIndex -ErrorAction SilentlyContinue }
               else { Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq "Up" | Select-Object -First 1 }
    $ip      = if ($placa) { (Get-NetIPAddress -InterfaceIndex $placa.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress }
    $link    = [bool]($placa -and $placa.Status -eq "Up")

    if (-not $operadora -and ((Get-Date) - $ultimaBusca).TotalMinutes -ge 60) {
        $operadora = DescobrirOperadora; $ultimaBusca = Get-Date
    }

    $rRoteador  = if ($link) { Responde $gateway } else { $false }
    $rOperadora = if ($rRoteador) { Responde $operadora } else { $null }
    $rNet1      = if ($rRoteador) { Responde $Publicos[0] } else { $false }
    $rNet2      = if ($rRoteador) { Responde $Publicos[1] } else { $false }
    $internet   = ($rNet1 -or $rNet2)
    $dnsRot     = if ($internet) { Resolve $gateway } else { $null }
    $dnsPub     = if ($internet) { Resolve $Publicos[0] } else { $null }

    $situacao =
        if (-not $link)                         { "SEM CABO/PLACA" }
        elseif (-not $rRoteador)                { "SEM ROTEADOR" }
        elseif ($rOperadora -eq $false -and -not $internet) { "ROTEADOR SEM ONT" }
        elseif (-not $internet)                 { "OPERADORA SEM INTERNET" }
        elseif (-not $dnsRot -and $dnsPub)      { "DNS DO ROTEADOR" }
        elseif (-not $dnsRot -and -not $dnsPub) { "SEM DNS" }
        else                                    { "OK" }

    $csv = Join-Path $Pasta ("conexao-" + $inicio.ToString("yyyy-MM-dd") + ".csv")
    if (-not (Test-Path $csv)) {
        Add-Content -Path $csv -Value "DataHora;Situacao;IP;Placa;Roteador;Operadora;Internet1;Internet2;DNS_Roteador;DNS_Publico"
    }
    Add-Content -Path $csv -Value ("{0:dd/MM/yyyy HH:mm:ss};{1};{2};{3};{4};{5};{6};{7};{8};{9}" -f $inicio, $situacao, $ip,
        (Texto $link), (Texto $rRoteador), (Texto $rOperadora), (Texto $rNet1), (Texto $rNet2), (Texto $dnsRot), (Texto $dnsPub))

    if ($situacao -ne $situacaoAntes) {
        if ($null -ne $situacaoAntes) {
            $dur = $inicio - $desde
            Evento ("{0} -> {1}   (a situacao anterior durou {2:hh\:mm\:ss}; IP desta maquina: {3})" -f $situacaoAntes, $situacao, $dur, $ip)
        } else {
            Evento ("Situacao inicial: {0} (IP desta maquina: {1})" -f $situacao, $ip)
        }
        $situacaoAntes = $situacao
        $desde = $inicio
    }

    # Limpeza dos arquivos antigos, uma vez por dia (perto da meia-noite)
    if ($inicio.Hour -eq 0 -and $inicio.Minute -eq 0) {
        Get-ChildItem $Pasta -File -Include *.csv, *.log -Recurse |
            Where-Object { $_.LastWriteTime -lt $inicio.AddDays(-$DiasGuardar) } | Remove-Item -Force
    }

    $espera = $Intervalo - ((Get-Date) - $inicio).TotalSeconds
    if ($espera -gt 0) { Start-Sleep -Seconds ([int][math]::Ceiling($espera)) }
}
