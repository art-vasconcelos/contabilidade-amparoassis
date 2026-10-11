# Incidente – Servidor subiu pelo SSD antigo após queda de energia

| Campo | Valor |
|---|---|
| Data da queda de energia | [DEFINIR] |
| Comunicado por | Natalia, em 11/10/2026 |
| Atendimento | Remoto (AnyDesk) · presencial depois, para bateria e nobreak |
| Status | 🟡 Em andamento |
| Horas | [DEFINIR] |
| Roteiro técnico | `02-tecnico/incidente-boot-ssd-antigo/roteiro.md` |

## O que aconteceu

Depois de uma queda de energia, o servidor ligou pelo SSD antigo (SATA 1 TB), que tinha ficado
na máquina como reserva da migração, e não pelo SSD novo (NVMe 2 TB). O escritório trabalhou
alguns dias nele sem perceber. O Artur reativou o boot pelo NVMe 2 TB.

## Impacto

O que foi lançado durante os dias no SSD antigo não aparece no sistema atual, e o SSD antigo
não tem nada do que foi feito entre a migração e a queda. Os dois discos ficaram com dados
diferentes, e nenhum deles tem tudo.

## Causa provável

A configuração da placa-mãe voltou ao padrão depois da queda de energia, o que é comum com a
bateria da placa-mãe fraca, e passou a dar boot pelo SSD antigo. A causa foi possível porque
os dois discos clonados continuavam ligados e prontos para dar boot. O servidor não tinha
nobreak.

## Ações

| Data | Ação | Situação |
|---|---|---|
| 11/10/2026 | Boot reativado pelo NVMe 2 TB | ✅ |
| 11/10/2026 | Roteiro e scripts de recuperação preparados | ✅ |
| [DEFINIR] | Backup do banco atual (fase 0) | ⏳ |
| [DEFINIR] | Diagnóstico e cópia do que só existe no SSD antigo (fases 1 a 3) | ⏳ |
| [DEFINIR] | Decisão sobre o banco do sistema da folha: refazer lançamentos ou acionar o fornecedor (fase 4) | ⏳ |
| [DEFINIR] | Igualar os discos e criar a rotina noturna (fase 5) | ⏳ |
| [DEFINIR] | Bateria da placa-mãe e nobreak (fase 6). Em compra pelo escritório | ⏳ |

## Lições

1. Dois discos clonados e prontos para dar boot, ligados na mesma máquina, são um risco: depois
   de uma falha, o servidor pode subir pelo disco errado sem ninguém notar.
2. Um servidor sem nobreak está exposto a toda queda de energia.
3. O caso reforça a necessidade de uma cópia automática e testada do banco e de acompanhamento
   do servidor, como na proposta enviada.
