# Incidente – Servidor subiu pelo SSD antigo após queda de energia

| Campo | Valor |
|---|---|
| Início no SSD antigo | **24/09/2026 22:02**, na noite da migração (corrigido em 17/10; o diagnóstico de 16/10 apontava 06/10) |
| Comunicado por | Natalia, em 11/10/2026 |
| Atendimento | Remoto (AnyDesk) · presencial depois, para bateria e nobreak |
| Status | 🟡 Em andamento: servidor ainda rodando pelo SSD antigo |
| Horas | 11/10: [DEFINIR] · 16/10: 1h (ver `controle-de-horas.md`) |
| Roteiro técnico | `02-tecnico/incidente-boot-ssd-antigo/roteiro.md` |

## O que aconteceu

> **Correção de 17/10/2026.** O diagnóstico de 16/10 dizia que o servidor ligava pelo SSD
> antigo desde 06/10. A leitura completa dos logs dos dois discos mostrou outra coisa: **o NVMe
> só ligou em 24/09, na noite da migração**, e às 22:02 do mesmo dia o servidor já voltou a
> ligar pelo SSD antigo. Desde então, todo o trabalho do escritório está no SSD antigo, e o NVMe
> praticamente não tem nada que falte no antigo.

Depois da migração para o NVMe 2 TB, em 24/09, o servidor voltou a ligar pelo SSD antigo
(SATA 1 TB), que tinha ficado na máquina como reserva. O escritório trabalhou nele desde
então. Em 11/10, o Artur tentou reativar o boot pelo NVMe, mas **a mudança não chegou a
valer**. A ordem de boot do firmware aponta o "Windows Boot Manager" para a partição de
sistema do SSD antigo.

### Linha do tempo (logs do Windows dos dois discos, lidos em 17/10)

| Data/hora | Evento | Disco |
|---|---|---|
| 18/09 a 24/09 20:14 | Histórico igual nos dois logs (clone feito em 24/09, entre 18:51 e 20:14) | — |
| 24/09 21:28 | Desligamento inesperado e boot pelo **NVMe**. É o último registro do log do NVMe | NVMe |
| 24/09 21:43 – 21:57 | Sistema da folha registra falha de banco (`DiagFalhaBD`) no NVMe; última gravação do banco do NVMe às 21:56 | NVMe |
| 24/09 22:02, 22:09 e 22:12 | Boots pelo **SSD antigo**. Ele segue em uso desde então | SATA |
| 25/09, 27/09 (2×), 05/10, 06/10 (3×), 09/10, 13/10 e 16/10 | **Desligamentos inesperados: 10 em pouco mais de 3 semanas** | SATA |

Vários eventos 6008 registram o horário do desligamento **depois** do horário em que o
Windows religou (ex.: em 25/09 14:15, "desligamento às 16:55 de 26/09"). Isso indica que o
relógio da placa-mãe se perdeu nas quedas, outro sinal de bateria da placa-mãe fraca.

### Letras dos discos (16/10)

| Disco | Modelo | Letras |
|---|---|---|
| 0 | SSD 1 TB SATA (antigo, **em uso**) | C: Sistema · D: Dados (compartilhamentos `Empresas` e `Rede - Amparo`) |
| 1 | Kingston NVMe 2 TB (parado desde 24/09) | E: Sistema · F: Dados |
| 2 | Seagate Expansion USB | G: HD externo |

## Impacto

- **SSD antigo (em uso):** tem todo o trabalho desde a migração.
- **NVMe (parado):** tem só o estado do dia da migração, mais cerca de meia hora de 24/09 à
  noite. A conferência de 17/10 (planilhas do script 04) confirma se há algo dele a guardar.
- Não há bancos para juntar e não é preciso acionar a IOB/Sage, desde que a conferência confirme.

## Causa provável

A configuração da placa-mãe voltou ao padrão depois da queda de energia, o que é comum com a
bateria da placa-mãe fraca, e passou a dar boot pelo SSD antigo. A causa foi possível porque
os dois discos clonados continuavam ligados e prontos para dar boot. O servidor não tinha
nobreak.

## Ações

| Data | Ação | Situação |
|---|---|---|
| 11/10/2026 | Tentativa de reativar o boot pelo NVMe 2 TB | ❌ Não valeu |
| 11/10/2026 | Roteiro e scripts de recuperação preparados | ✅ |
| 16/10/2026 | Computadores sem acesso às pastas do servidor: a rede do servidor estava como `Public`. Corrigido para `Private` e regra de compartilhamento liberada no firewall | ✅ |
| 16/10/2026 | Diagnóstico: servidor rodando pelo SSD antigo desde 06/10 (corrigido em 17/10: desde 24/09); 3 desligamentos inesperados (09, 13 e 16/10); `_socket.vcx` (erro 1993) ausente nos dois discos | ✅ |
| [DEFINIR] | Backup do banco em uso no HD externo G: (fase 0) | ⏳ |
| 17/10/2026 | Leitura dos logs dos dois discos: NVMe parado desde 24/09; nada de 25/09 em diante ficou só nele. Acionar a IOB/Sage deixa de ser necessário, se a conferência confirmar | ✅ |
| 17/10/2026 | Backup do banco e da pasta do sistema da folha no G: (sem falhas) e clone SSD antigo → NVMe, conferido arquivo por arquivo (`2026-10-17-backup-e-clonagem.md`) | ✅ |
| [DEFINIR] | Visita: passar a ligar pelo NVMe com o SSD antigo desconectado e recuperar o acesso remoto | ⏳ |
| [DEFINIR] | Cópia do que só existe no NVMe: banco (pasta data em E:) e arquivos de F: (fases 1 a 3) | ⏳ |
| [DEFINIR] | Decisão sobre o banco do sistema da folha: refazer lançamentos ou acionar o fornecedor (fase 4) | ⏳ |
| [DEFINIR] | Igualar os discos e criar a rotina noturna (fase 5) | ⏳ |
| [DEFINIR] | Bateria da placa-mãe e nobreak (fase 6). Em compra pelo escritório | ⏳ |

## Lições

1. Dois discos clonados e prontos para dar boot, ligados na mesma máquina, são um risco: depois
   de uma falha, o servidor pode subir pelo disco errado sem ninguém notar.
2. Um servidor sem nobreak está exposto a toda queda de energia.
3. Depois de um reinício inesperado, o Windows pode classificar a rede como `Public` e bloquear
   o compartilhamento de pastas. O tipo de rede deve ser conferido após cada queda (incluir no
   monitoramento). O servidor também ainda recebe IP por DHCP: falta uma reserva no roteador.
4. O caso reforça a necessidade de uma cópia automática e testada do banco e de acompanhamento
   do servidor, como na proposta enviada.
