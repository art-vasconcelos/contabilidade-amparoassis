# Plano – Clonar o SSD antigo para o NVMe (remoto)

Pedido da Natalia em 17/10/2026: deixar os dois discos iguais.
Contexto: `roteiro.md` e `01-historico/2026-10-incidente-boot-ssd-antigo.md`.

## Execução

| Data | Início | Fim | Remoto/presencial |
|---|---|---|---|
| 17/10/2026 | 15:30 | [DEFINIR] | Remoto (AnyDesk) |

## Situação de partida

| Disco | Letras | Estado | Tem só nele |
|---|---|---|---|
| 0 · SSD SATA 1 TB (antigo) | C: Sistema · D: Dados | **Em uso** desde 06/10 20:32 | Tudo de 06/10 em diante |
| 1 · NVMe Kingston 2 TB | E: Sistema · F: Dados | Parado desde 06/10 | O que foi feito entre a migração e 06/10 |
| 2 · HD externo USB | G: | Backup | — |

**Direção do clone: SATA (em uso) → NVMe.** O disco em uso tem o trabalho dos últimos dias e
está funcionando. O NVMe será apagado, então **antes** guardamos no HD externo o que só existe
nele (etapas 2 e 3). O clone não piora nada: o sistema já roda sem esses dados desde 06/10, e
eles ficam guardados para o suporte da IOB/Sage ou para a equipe refazer.

## Divisão remoto × presencial

| Parte | Onde | Risco |
|---|---|---|
| Etapas 0 a 4: conferir, guardar o NVMe, backup e clone | **Remoto** | Baixo: o servidor continua ligado pelo mesmo disco o tempo todo |
| Etapa 5: passar a ligar pelo NVMe | **Presencial** (com a bateria e o nobreak) ou remoto com alguém no escritório | Médio: se não ligar, alguém precisa apertar F12 |

Com os dois discos clonados e ligados, o Windows pode confundir os discos na hora de trocar o
boot. Por isso a troca fica para quando der para desconectar o SATA com a mão, ou pelo menos com
alguém no escritório.

## Pré-requisitos

- [ ] Escritório sem ninguém usando o sistema da folha durante a etapa 4 (o banco fica parado).
- [ ] Natalia ciente de que os lançamentos do NVMe (migração → 06/10) ficam **guardados no HD
      externo**, mas não voltam sozinhos para o sistema.
- [ ] Senha do usuário `postgres` [VER COFRE]: opcional. Sem ela, o backup da etapa 2 é feito
      copiando a pasta do banco com o serviço parado.
- [ ] Scripts copiados para o servidor em `C:\Suporte\scripts` (transferência de arquivos do AnyDesk).

Antes de rodar os scripts, no PowerShell como administrador:

```powershell
cd C:\Suporte\scripts
Set-ExecutionPolicy -Scope Process Bypass -Force
```

## Etapa 0 – Conferência (só leitura)

```powershell
Get-Disk | Sort-Object Number | Format-Table Number, FriendlyName, @{n="GB";e={[math]::Round($_.Size/1GB)}}, IsBoot, IsOffline, IsReadOnly, PartitionStyle -AutoSize
Get-Volume | Where-Object DriveLetter | Sort-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, @{n="UsadoGB";e={[math]::Round(($_.Size-$_.SizeRemaining)/1GB,1)}}, @{n="LivreGB";e={[math]::Round($_.SizeRemaining/1GB,1)}} -AutoSize
Get-CimInstance Win32_Service | Where-Object { $_.PathName -match "pg_ctl" } | Format-List Name, State, PathName
```

Anotar:
- [ ] Disco 0 continua `IsBoot = True` (SATA) e o NVMe continua com E: e F:.
- [ ] Espaço livre no G: (precisa caber o backup do banco, a pasta do banco do NVMe e os arquivos alterados).
- [ ] Nome do serviço do PostgreSQL e caminho da pasta `data` (parâmetro `-D` no `PathName`).

**Resultado de 17/10, 16:31:**

| Disco | Modelo | GB | Boot | Partições (usado / livre em GB) |
|---|---|---|---|---|
| 0 | SSD 1TB (GPT) | 932 | **Sim** | C: Sistema 143,2 / 103,7 · D: Dados 156,2 / 527,4 |
| 1 | KINGSTON SNV3S2000G (GPT) | 1863 | Não, online | E: Sistema 162,5 / 84,4 · F: Dados 155,1 / 1460 |
| 2 | Seagate Expansion (MBR) | 1863 | Não | G: "Thaís" 925,2 / 937,8 |

- Serviço do banco: `postgresql-x64-10`, rodando. Pasta `data`: `C:\PostgreSQL\10\data` (no NVMe: `E:\PostgreSQL\10\data`).
- O HD externo tem 937,8 GB livres: cabe com folga o backup do banco, a cópia do NVMe e os arquivos alterados.
- Usar o **Windows PowerShell 64 bits**, e não o "(x86)": o `bcdedit` não existe na versão 32 bits.

## Etapa 1 – Data da migração (só leitura)

O log do Windows do NVMe mostra quando ele começou a ser usado:

```powershell
.\01-diagnostico.ps1 -LetraSsdAntigo E
```

Na última seção (o título diz "SSD ANTIGO", mas o log lido é o de `E:`, o NVMe), o primeiro
"Windows iniciou" é a data da migração.

- [x] Data da migração: **24/09/2026**. O log do NVMe termina em 24/09 21:28. O SSD antigo
      liga desde 24/09 22:02, então o NVMe só tem cerca de meia hora a mais que o antigo, e não
      os dias até 06/10, como se pensava em 16/10.
- Consequência: a etapa 3 vira uma **conferência** com `-Desde "2026-09-24 20:00"`. Se ela não
  mostrar nada relevante, não há o que devolver ao D: nem banco para juntar.

## Etapa 2 – Backup do banco em uso

O clone não precisa da senha do banco. Este backup é uma rede de segurança antes de mexer
no NVMe. Há duas formas:

**Com a senha do `postgres`** (pode rodar com o escritório trabalhando):

```powershell
.\02-backup-banco-atual.ps1 -Destino G:\Backup-Banco
```

Se a senha não for conhecida, tentar só apertar Enter: alguns servidores aceitam conexão local
sem senha.

**Sem a senha** (com o escritório sem uso, logo antes da etapa 4): parar o banco e copiar a
pasta `data` inteira. Com o serviço parado, a cópia é um backup completo.

```powershell
Stop-Service postgresql-x64-10
robocopy "C:\PostgreSQL\10\data" "G:\Backup-Banco-SSD-antigo\data" /E /COPY:DAT /DCOPY:T /R:1 /W:1 /NP /LOG:G:\Backup-Banco-SSD-antigo.log
# conferir no log: linha "Falhas" (Failed) zerada; depois seguir direto para a etapa 4 com o banco parado
```

## Etapa 3 – Guardar o que só existe no NVMe (só lê o NVMe)

**3a. Pasta do banco do NVMe.** Mesmo caminho da pasta `data` da etapa 0, trocando `C:` por `E:`:

```powershell
.\03-copiar-banco-ssd-antigo.ps1 -Origem "E:\PostgreSQL\10\data" -Destino G:\Banco-NVMe-ate-06-10
```

**3b. Pasta do sistema da folha no NVMe**, inteira, por segurança (é pequena e é onde o erro 1993 apontava):

```powershell
robocopy "E:\Folhamatic" "G:\Folhamatic-NVMe-ate-06-10" /E /COPY:DAT /DCOPY:T /R:1 /W:1 /NP /LOG:G:\Folhamatic-NVMe-ate-06-10.log
```

**3c. Arquivos alterados entre a migração e 06/10**, nas duas partições do NVMe:

```powershell
$migracao = "<data da etapa 1>"   # ex.: "2026-10-02 18:00"
.\04-arquivos-alterados.ps1 -RaizAntigo F:\ -RaizAtual D:\ -Desde $migracao -Ate "2026-10-06 20:32" -Saida C:\Suporte\alterados-nvme-F.csv
.\04-arquivos-alterados.ps1 -RaizAntigo E:\ -RaizAtual C:\ -Desde $migracao -Ate "2026-10-06 20:32" -Saida C:\Suporte\alterados-nvme-E.csv

.\05-guardar-arquivos-alterados.ps1 -Planilha C:\Suporte\alterados-nvme-F.csv -RaizOrigem F:\ -Destino G:\Arquivos-NVMe\F
.\05-guardar-arquivos-alterados.ps1 -Planilha C:\Suporte\alterados-nvme-E.csv -RaizOrigem E:\ -Destino G:\Arquivos-NVMe\E
```

Nas planilhas, "SSD antigo" quer dizer o NVMe (o disco passado em `-RaizAntigo`).

**3d. Devolver os arquivos da equipe para o disco em uso (F: → D:).** Revisar a planilha
`alterados-nvme-F.csv` com a Natalia e apagar as linhas que não devem voltar. Salvar como
`alterados-nvme-F-revisada.csv` e rodar:

```powershell
.\05-guardar-arquivos-alterados.ps1 -Planilha C:\Suporte\alterados-nvme-F-revisada.csv -RaizOrigem F:\ -Destino D:\ -BackupSubstituidos G:\Substituidos-D
```

- Só entram as linhas "So no SSD antigo" e "Antigo mais recente". A versão do D: que for
  substituída fica guardada em `G:\Substituidos-D`.
- Linhas "Atual mais recente" são **conflito**: o arquivo foi mexido nos dois discos. Decidir
  com a equipe, uma a uma.
- A partição do sistema (E: → C:) **não** é devolvida: são arquivos do Windows e de programas.
  A planilha `alterados-nvme-E.csv` serve só para conferência.
- **O banco não entra aqui.** Não dá para juntar dois bancos copiando arquivos: a pasta do banco
  é um bloco só, e copiar a do NVMe por cima apagaria os dias de trabalho no SSD antigo. Os
  lançamentos do NVMe ficam guardados (3a) até a equipe refazer ou a IOB/Sage juntar.

**Resultado da conferência de 17/10, 16:38–16:45** (`-Desde "2026-09-24 20:00"`):

| Partição do NVMe | So no NVMe | NVMe mais recente | Atual mais recente | Iguais | Leitura |
|---|---|---|---|---|---|
| F: (Dados) | 0 | 0 | 2 (OneDrive) | 0 | Nada a devolver ao D: |
| E: (Sistema) | 19 | 1 | 64 | 4 | Quase tudo é cache e log do Windows, AnyDesk e OneDrive. Há 6 arquivos em `Folhamatic\FolhaWin\central` e `central\dados` para conferir |

**Detalhe (16:50):**
- Banco do NVMe: última gravação em **24/09 21:56** (`pg_control` e log). Nenhum lançamento depois da migração.
- Sistema da folha: só `atualizador\dados\ATUALIZACAO.CDX` está mais novo no NVMe. É o índice de
  `ATUALIZACAO.DBF`, que está mais novo no disco em uso, então **não deve ser copiado**: o índice
  ficaria fora de sincronia com a tabela. Os outros arquivos são mais novos no disco em uso.
- Só no NVMe: logs `DiagFalhaBD` de 24/09 21:43 a 21:57 (o sistema da folha registrou falha de
  banco na noite da migração, pouco antes de o servidor voltar ao SSD antigo às 22:02), logs do
  Windows e cache. Nada a recuperar.
- **Conclusão: as etapas 3a a 3d não são necessárias. Seguir para o backup e o clone.**

**Ponto de parada:** só seguir para a etapa 4 com as etapas 2 e 3 concluídas e sem erro.

## Etapa 4 – Clone SATA → NVMe (escritório sem uso)

Ferramenta: **Hasleo Disk Clone** (gratuita, clona o disco do sistema com o Windows ligado).
Baixar do site oficial (`easyuefi.com`).

1. Parar o banco para a cópia ficar limpa (se já estiver parado pela etapa 2, seguir):
   ```powershell
   Stop-Service postgresql-x64-10
   ```
2. No Hasleo Disk Clone: **Disk Clone** → origem **Disco 0 (SATA 1 TB)** → destino **Disco 1
   (NVMe 2 TB)**. Conferir duas vezes pelo modelo e tamanho: o destino é apagado.
3. Ajustar as partições para usar os 2 TB (aumentar a última partição, a de Dados) e marcar a
   opção de otimização para SSD, se aparecer.
4. Esperar terminar. O servidor continua ligado pelo SATA.
5. Subir o banco e conferir:
   ```powershell
   Start-Service postgresql-x64-10
   Get-Disk | Sort-Object Number | Format-Table Number, FriendlyName, IsBoot, IsOffline -AutoSize
   ```
   É normal o NVMe aparecer **offline** (o Windows faz isso com discos clonados). Deixar assim.
6. Pedir para alguém abrir o sistema da folha em um computador da equipe, ou testar pelo AnyDesk.

- [ ] Clone concluído em: [DEFINIR]

## Etapa 5 – Passar a ligar pelo NVMe (presencial, recomendado)

Junto com a troca da bateria da placa-mãe e a instalação do nobreak (fase 6 do `roteiro.md`):

1. Se o escritório trabalhou depois do clone, refazer o clone (etapa 4) antes de trocar.
2. Desligar o servidor e **desconectar o cabo do SSD SATA**.
3. Na placa-mãe (F2): NVMe em primeiro lugar e senha de administrador da configuração.
4. Ligar e conferir: `Get-Disk` mostra o NVMe com `IsBoot = True`, os compartilhamentos
   funcionam, a rede está `Private` e o sistema da folha abre nos computadores da equipe.
5. Reconectar o SATA só quando for usado como destino da rotina noturna (fase 5 do `roteiro.md`).

**Alternativa remota:** só com alguém no escritório para apertar F12 se o servidor não ligar.
Boot único pelo NVMe, sem mudar a ordem permanente:

```powershell
bcdedit /enum firmware                                   # achar a entrada do NVMe
bcdedit /set {fwbootmgr} bootsequence {<id-da-entrada-do-nvme>}
shutdown /r /t 0
```

Depois de religar, conferir se o NVMe está com `IsBoot = True`. Se o disco errado ligar, o
próximo reinício volta para o SATA sozinho.

## Depois do clone

- [ ] Atualizar o histórico do incidente e a ficha do cliente.
- [ ] Decidir a rotina noturna (opção A ou B do `roteiro.md`, fase 5).
- [ ] Decidir com a Natalia o destino dos lançamentos guardados do NVMe (IOB/Sage ou a equipe refaz).
- [ ] Registrar as horas em `01-historico/controle-de-horas.md`.
