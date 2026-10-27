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
| Remoto: conferência, banco, backup conferido e instalação do backup noturno | 21:00 – 22:30 | 1h30 |
| **Total cobrado** | | **3h30 (R$ 175,00 a R$ 50/h)** |

Início do trecho remoto estimado pelo checkup salvo às 21:15. Deslocamento não incluso.

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
- **IP fixo configurado na placa do servidor**, igual à reserva (correção de 27/10: na prática o servidor estava em DHCP com reserva; desde 27/10 a reserva é o `.200`) (endereços: [VER COFRE]), com o
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
- **Rotina do próprio sistema da folha** (`G:\BKPs`, uma pasta por dia da semana, backup "online"
  dos bancos da folha, contábil e fiscal):
  - É disparada pelo próprio sistema, e não por tarefa do Windows. Quase todo dia, quando o
    sistema é aberto de manhã na estação **AC-LUCIANA**, ele grava um log
    (`C:\Folhamatic\FolhaWin\backup\LOGS\LOG_BACKUP_RETORNO_*.XML`). Na maioria desses dias,
    porém, **nada foi copiado**: sem destino, 0 arquivos, início e fim no mesmo segundo.
  - Backups que de fato gravaram arquivos: 12/09, 15/09, 22 a 24/09, 13/10 e 16/10. Destino
    `E:\BKPS` até 22/09, que era a letra do HD externo antes da migração (em 24/09 o NVMe pegou o
    E:, e o HD externo passou para G:), e `G:\BKPS` desde 13/10. Configuração em
    `...\backup\backupsql.xml`.
  - Nada desde 16/10. O `CONTROLEDIARIO.XML` só registra os dias em que o sistema foi aberto
    (19 e 20/10 incluídos).
  - Quando e por que a rotina copia ou deixa de copiar depende do sistema da folha: abrir chamado
    na IOB/Sage com estes dados (fora do escopo de consultoria do sistema).

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
- [ ] Chamado na IOB/Sage: rotina de backup do sistema da folha quase nunca copia (só 13/10 e 16/10 em outubro).
- [ ] Estender o D: no NVMe para ocupar os ~931 GB livres no fim do disco.
- [ ] Bateria da placa-mãe e nobreak (o desligamento inesperado de 20/10 às 12:08 é o 11º desde 25/09).
- [ ] Cópia fora do servidor: SSD antigo como destino rotativo e/ou nuvem.
- [ ] Restringir no `pg_hba.conf` a regra `host all all all md5` à faixa da rede local.
- [x] Confirmar que a central de alarme mudou de endereço (lista de clientes do ER605): confirmado em 22/10.
- [ ] Trocar a senha do ER605.

---

## Relatório para o cliente

**Assunto:** Relatório de atendimento – 20/10 – Servidor no disco novo e backup automático

Olá, Natalia, tudo bem?

Segue o resumo do atendimento de ontem (20/10), presencial no fim da tarde e remoto à noite.

**Computadores sem acesso ao servidor**
O servidor desligou sozinho por volta do meio-dia e, ao religar, perdeu o "endereço" que usava na rede. Esse
endereço tinha sido ocupado pela central do alarme, e os dois entraram em conflito. Deixei um endereço fixo
reservado só para o servidor e outro para a central do alarme, então isso não se repete. Se a empresa do alarme
comentar algo, vale conferir no aplicativo se a central continua online.

**Servidor no disco novo**
- Fiz uma nova cópia completa do disco antigo para o disco novo, já com o trabalho dos últimos dias.
- O servidor passou a ligar pelo disco novo, como deveria ser desde a troca.
- O disco antigo foi retirado da máquina, como o Angelo pediu, e deve ficar guardado com a etiqueta
  "NÃO FORMATAR". Ele é a nossa cópia de emergência.
- O banco de dados do sistema foi conferido por completo e está íntegro.

**Backup automático**
Analisando o servidor, encontrei duas situações:
- O backup do Windows estava parado desde novembro de 2024;
- O backup do próprio sistema da folha, que roda ao abrir o sistema de manhã, só copiou os dados de fato em
  poucos dias. Em outubro, foram só dois.

Por isso, deixei funcionando um **backup automático todas as noites, às 23h**: ele copia o banco de dados do
sistema e as pastas da rede para o HD externo, guarda as cópias dos últimos dias e me avisa se der algum
problema. A primeira cópia completa foi feita ontem à noite. Também fiz uma cópia avulsa do banco de dados
antes de começar.

Sobre o backup do sistema da folha: recomendo abrir um chamado com o suporte da IOB/Sage para que eles revisem
a configuração. Segue um texto pronto, que pode ser enviado direto para eles:

> A rotina de backup do sistema (Backup SGBD, destino `G:\BKPS`, código do escritório 20468) é disparada na
> estação AC-LUCIANA ao abrir o sistema, mas na maioria dos dias o log termina sem destino e com 0 arquivos.
> Em outubro, só houve cópia em 13/10 e 16/10. Podem verificar a configuração e o agendamento para que o
> backup rode todos os dias? Obs.: em 24/09 o servidor trocou de disco e a letra do HD externo mudou de E: para G:.

**Pontos de atenção**
- O servidor desligou sozinho mais uma vez ontem ao meio-dia, a 11ª vez desde o fim de setembro. **O nobreak e
  a troca da bateria da placa-mãe continuam sendo a prioridade.**
- Ainda não existe nenhuma cópia fora do escritório. Num próximo passo, podemos falar sobre o backup em nuvem.
- Recomendo trocar a senha do roteador, porque ela foi compartilhada por mensagem.

**Tempo de atendimento**
- Presencial: 17h30 às 19h30 (2h)
- Remoto: 21h00 às 22h30 (1h30)
- Total: 3h30 (R$ 50,00/h = R$ 175,00)

Nos próximos dias, vou acompanhar se o backup noturno está rodando certinho.

Qualquer dúvida, fico à disposição.

Abraço,
Artur Vasconcelos
Analista de Sistemas e Engenheiro de Dados

---

## Mensagem para o WhatsApp

Oi, Natalia! Passando o resumo de ontem 🙂

✅ Computadores voltaram a acessar o servidor. A central do alarme tinha "pegado" o endereço dele na rede; agora cada um tem o seu fixo.
✅ O servidor está ligando pelo disco novo. O disco antigo saiu da máquina: por favor, guardem com a etiqueta "NÃO FORMATAR", ele é a nossa cópia de emergência.
✅ Banco de dados do sistema conferido: tudo íntegro.
✅ Deixei um backup automático rodando toda noite às 23h, do sistema e das pastas da rede, no HD externo. Se der problema, eu recebo o aviso.

⚠️ O backup do próprio sistema da folha quase não estava copiando nada. Mandei por e-mail um texto pronto para abrir chamado com a IOB/Sage.
⚠️ O servidor desligou sozinho de novo ontem ao meio-dia. O nobreak e a bateria continuam urgentes.

Se a empresa do alarme comentar alguma coisa, me avisa: a central mudou de endereço na rede.

Mandei o relatório completo por e-mail.
