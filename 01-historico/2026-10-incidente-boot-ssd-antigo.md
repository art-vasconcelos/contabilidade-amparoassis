# Incidente – Servidor subiu pelo SSD antigo após queda de energia

| Campo | Valor |
|---|---|
| Início no SSD antigo | 06/10/2026 20:32 (log do Windows do SSD antigo) |
| Comunicado por | Natalia, em 11/10/2026 |
| Atendimento | Remoto (AnyDesk) · presencial depois, para bateria e nobreak |
| Status | 🟡 Em andamento: servidor ainda rodando pelo SSD antigo |
| Horas | 11/10: [DEFINIR] · 16/10: 1h (ver `controle-de-horas.md`) |
| Roteiro técnico | `02-tecnico/incidente-boot-ssd-antigo/roteiro.md` |

## O que aconteceu

Depois de uma queda de energia, o servidor ligou pelo SSD antigo (SATA 1 TB), que tinha ficado
na máquina como reserva da migração, e não pelo SSD novo (NVMe 2 TB). O escritório trabalhou
alguns dias nele sem perceber. Em 11/10, o Artur tentou reativar o boot pelo NVMe 2 TB, mas
**a mudança não chegou a valer**: em 16/10 o diagnóstico mostrou que o servidor continuava
ligado pelo SSD antigo (disco 0, SATA, `IsBoot = True`).

### Linha do tempo (eventos 6005/6006/6008 do Windows do SSD antigo)

| Data/hora | Evento |
|---|---|
| [DEFINIR] | Migração do SSD antigo para o NVMe 2 TB |
| 06/10 20:32 | Servidor passa a ligar pelo SSD antigo |
| 09/10 (antes de 14:02) | Desligamento inesperado; religa 14:02; reinício 14:44 |
| 13/10 (antes de 09:16) | Desligamento inesperado; religa 09:16 |
| 16/10 (antes de 08:09) | Desligamento inesperado; religa 08:09; mais 3 reinícios até 08:25 |

Causa dos desligamentos (energia ou travamento) e último uso do NVMe: [VERIFICAR] (comandos A,
B e C do atendimento de 16/10).

### Letras dos discos (16/10)

| Disco | Modelo | Letras |
|---|---|---|
| 0 | SSD 1 TB SATA (antigo, **em uso**) | C: Sistema · D: Dados (compartilhamentos `Empresas` e `Rede - Amparo`) |
| 1 | Kingston NVMe 2 TB (parado desde 06/10) | E: Sistema · F: Dados |
| 2 | Seagate Expansion USB | G: HD externo |

## Impacto

- **SSD antigo (em uso):** tem tudo de 06/10 em diante e falta o que foi feito entre a
  migração e 06/10.
- **NVMe (parado):** tem tudo da migração até 06/10 e falta tudo depois disso.
- Os dois discos ficaram com dados diferentes, e nenhum deles tem tudo. O tamanho da diferença
  depende da data da migração.

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
| 16/10/2026 | Diagnóstico: servidor rodando pelo SSD antigo desde 06/10; 3 desligamentos inesperados (09, 13 e 16/10); `_socket.vcx` (erro 1993) ausente nos dois discos | ✅ |
| [DEFINIR] | Backup do banco em uso no HD externo G: (fase 0) | ⏳ |
| [DEFINIR] | Suporte IOB/Sage: trazer para o banco em uso os lançamentos que só existem no NVMe (migração → 06/10) | ⏳ |
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
