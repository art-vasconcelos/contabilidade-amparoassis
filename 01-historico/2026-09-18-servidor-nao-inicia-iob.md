# 2026-09-18 a 20/09 — Servidor não iniciava o Windows e banco do IOB Office parado

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia (domingo), Sr. Ricardo (sexta) · Sr. Ângelo informado
**Atendimento:** presencial
**Status:** resolvido · migração para o SSD de 2 TB feita depois, em 24/09
**Relatório ao cliente:** enviado em 20/09 · pago

## Tempo

| Etapa | Data / horário | Duração |
|---|---|---|
| Visita de avaliação | sexta 18/09, 19:00 – 20:00 | sem custo |
| Auxílio na compra do SSD de 2 TB | sábado 19/09 | sem custo |
| Diagnóstico e correção | domingo 20/09, 09:00 – 13:00 | 4h00 |
| **Total cobrado** | | **4h00 (R$ 200,00 a R$ 50/h)** · já pago |

## Sintoma

- O Windows não iniciava (erro `0x7B`, disco do sistema não reconhecido).
- A configuração da BIOS parecia ter voltado ao padrão.
- Depois que o Windows voltou, o banco de dados do IOB Office ficou parado.

## O que foi feito

- Diagnóstico Dell de hardware e testes de software: o SSD passou em todos os testes e não
  precisou ser trocado. A compra do SSD de 2 TB foi mantida, para ganhar espaço.
- BIOS com avisos de data/hora não definida e configuração inválida, compatíveis com a bateria
  CR2032 fraca. O modo de armazenamento estava em `RAID On` e voltou para `AHCI`.
- CHKDSK e inicialização do Windows.
- Rede normal; banco de dados parado.
- Conferência do backup diário no HD externo.
- Cópia completa da pasta do banco (63,7 GB) no HD externo, conferida, antes de mexer no banco.
- Recriação de uma pasta temporária ausente do banco e recuperação automática dele.
- Desligamento limpo e reinício do banco pelo serviço do Windows.
- Atualização do IOB Office (sistema, tabelas do componente fiscal e demais componentes), com
  validação da Natalia.

## Causa

Não confirmada. Principal suspeita: bateria CR2032 da placa-mãe fraca.

## Recomendações deixadas

1. Trocar a bateria CR2032.
2. No futuro, avaliar um servidor dedicado com Windows Server 2016 ou 2019 (versões suportadas
   pela IOB). A IOB não homologa o IOB Office em máquina virtual.
3. Conferir de tempos em tempos a bateria do nobreak.
4. Manter o backup diário e acompanhar o espaço livre no HD externo.
