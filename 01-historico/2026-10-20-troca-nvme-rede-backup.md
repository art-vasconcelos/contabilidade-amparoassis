# 2026-10-20 — Servidor passa a ligar pelo NVMe, rede corrigida e backup noturno instalado

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia
**Atendimento:** presencial (17:30–19:30) + remoto à noite (TeamViewer), com apoio do Claude Code
**Status:** servidor no NVMe e funcionando · primeira execução do backup noturno em andamento
**Detalhes técnicos:** `02-tecnico/incidente-boot-ssd-antigo/plano-clonagem.md` (etapa 5) e
`02-tecnico/backup-monitoramento/scripts/`

## Tempo

| Etapa | Horário | Duração |
|---|---|---|
| Presencial: rede, roteador, novo clone e troca para o NVMe | 17:30 – 19:30 | 2h00 |
| Remoto: conferência, banco, backup conferido e instalação do backup noturno | 21:00 – [DEFINIR] | [DEFINIR] |
| **Total** | | **[DEFINIR]** |

Início do trecho remoto estimado pelo checkup salvo às 21:15. Confirmar o horário final.

## 1. Computadores sem acesso ao servidor (rede)

**Sintoma:** parte dos computadores sem acesso às pastas do servidor.

**Causa:** o servidor reiniciou sozinho às 12:08 (mais um desligamento inesperado) e, ao voltar,
recebeu outro endereço pelo DHCP. O endereço que ele usava antes tinha sido entregue pelo
roteador à **central de alarme Intelbras AMT 8000**, que fica na rede por Wi-Fi. Quando o
servidor tentou voltar ao endereço antigo, houve conflito e ele ficou sem rede.

**Solução:**
- Acesso ao roteador ER605 recuperado (usuário e senha: [VER COFRE]). Recomendado trocar a senha,
  que circulou por mensagem.
- Reservas de endereço no ER605: uma para o servidor e uma para a central de alarme, que vai
  trocar de endereço sozinha quando renovar o aluguel do IP. Nenhum redirecionamento de porta
  apontava para a central (Virtual Servers vazio).
- **IP fixo configurado na placa do servidor**, igual à reserva (endereços: [VER COFRE]), com o
  roteador e um DNS público como servidores de DNS.
- Os computadores acessam o servidor pelo nome, então não foi preciso remapear unidades.
- O reset do ER605 de 13/10 já tinha mudado a faixa da rede, o que confirma que os mapeamentos
  não dependem de IP.

**Avisar a Natalia:** a central de alarme vai mudar de endereço. Se a empresa do alarme
perguntar, conferir no aplicativo da Intelbras se ela continua online.

## 2. Servidor passa a ligar pelo NVMe

- Novo clone SSD antigo → NVMe pelo DiskGenius (**Tools → Clone Disk**, mesmas opções de 17/10),
  porque o escritório trabalhou depois do clone de sábado.
- **SSD antigo retirado da máquina** a pedido do Angelo. Etiquetar como "Servidor – cópia de
  20/10/2026 – NÃO FORMATAR" e guardar: é a reserva de emergência até a rotina noturna ter
  cópias fora do servidor.
- Boot pelo **NVMe Kingston** (`IsBoot = True`), letras C: Sistema e D: Dados mantidas,
  compartilhamentos `Empresas`, `Rede - Amparo` e `Folhamatic` online, rede `Private`.
- O IP fixo foi aplicado de novo no Windows do NVMe, porque o clone foi feito antes da mudança.
- O "desligamento inesperado às 17:59" no log do NVMe é o momento do clone: a cópia foi feita com
  o Windows ligado. Não houve queda de energia nesse horário.

## 3. Banco de dados

- No boot pelo NVMe, o PostgreSQL fez a **recuperação automática** (o banco estava ligado no
  momento do clone) e levou cerca de 4 minutos. O Windows desistiu de esperar depois de 60
  segundos e marcou o serviço como parado, mas o banco já estava no ar.
- Corrigido: banco desligado de forma limpa e religado pelo serviço.
- **Espera do serviço aumentada para 10 minutos** (`-t 600` no serviço `postgresql-x64-10`).
  Assim, depois de uma queda de energia, o serviço não aparece mais como parado durante a
  recuperação.
- Integridade conferida com um **backup completo** (`pg_dump` lê todas as tabelas), sem erros:
  `contabil` 224,8 MB, `efiscal` 604,3 MB e `folha` 591,2 MB, em `G:\Backup-Banco\2026-10-20_2134`.
- Descoberta: o administrador dos bancos é o usuário **`sageuser`**, do fornecedor. O `postgres`
  não tem acesso aos dados. Nenhuma senha conhecida. O acesso sem senha foi liberado só de dentro
  do servidor e só durante o backup, e o `pg_hba.conf` voltou ao original (conferido).

## 4. Backup noturno

**Situação encontrada:**
- **Backup do Windows (`wbadmin`):** parado desde 09/11/2024.
- **Rotina do próprio sistema da folha** (`G:\BKPs`, uma pasta por dia da semana): configurada
  para `E:\BKPS` até 22/09. Na migração (24/09), o NVMe pegou a letra E: e o HD externo passou
  para G:, e a rotina deixou de gravar no HD externo. Em 13/10 foi reapontada para `G:\BKPS`, mas
  desde então só rodou em 13/10 e 16/10. Configuração: `C:\Folhamatic\FolhaWin\backup\backupsql.xml`
  e logs em `...\backup\LOGS`. Reparo: [DEFINIR], por nós ou pelo suporte IOB/Sage.

**Instalado (`instalar-backup-noturno.ps1`):**
- Tarefa agendada **"Amparo - Backup noturno"**, todo dia às 23:00, como SYSTEM. Se o servidor
  estiver desligado no horário, ela roda quando ele ligar.
- `pg_dump` dos bancos conferido com `pg_restore -l`. Ficam os backups dos últimos 14 dias e os
  de domingo dos últimos 60 dias, em `G:\Backup-Noturno\banco`.
- Cópia de `D:\Empresas`, `D:\Rede - Amparo` e `C:\Folhamatic` para `G:\Backup-Noturno\arquivos`.
  O que for apagado no servidor continua guardado no backup.
- Usuário próprio no banco, **`backup_amparo`**, aceito só de dentro do servidor. A senha está em
  `C:\Suporte\backup\pgpass.conf` (só SYSTEM e Administradores leem) e no cofre: [VER COFRE].
  As senhas do `postgres` e do `sageuser` não foram alteradas.
- Resultado em `C:\Suporte\backup\ultimo-resultado.txt`, nos logs em `C:\Suporte\backup\logs`, no
  log de eventos do Windows (origem "Backup Amparo", evento 1000 = OK e 1001 = falha) e, se
  configurado, aviso no celular pelo app ntfy (tópico: [VER COFRE]).
- Primeira execução iniciada à mão na mesma noite. Resultado: [VERIFICAR].

## Pendências

- [ ] Conferir o resultado da primeira execução do backup noturno e das próximas duas noites.
- [ ] Reparar ou pedir ao suporte IOB/Sage o reparo da rotina de backup do sistema da folha.
- [ ] Estender o D: no NVMe para ocupar os ~931 GB livres no fim do disco.
- [ ] Bateria da placa-mãe e nobreak (o desligamento inesperado de 20/10 às 12:08 é o 11º desde 25/09).
- [ ] Cópia fora do servidor: SSD antigo como destino rotativo e/ou nuvem.
- [ ] Restringir no `pg_hba.conf` a regra `host all all all md5` à faixa da rede local.
- [ ] Confirmar que a central de alarme mudou de endereço (lista de clientes do ER605).
- [ ] Trocar a senha do ER605.
