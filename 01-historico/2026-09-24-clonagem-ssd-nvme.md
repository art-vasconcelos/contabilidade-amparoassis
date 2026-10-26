# 2026-09-24 e 25/09 — Migração do SSD SATA 1 TB para o NVMe 2 TB e banco que não subia

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia
**Atendimento:** presencial em 24/09 · 25/09 em horários quebrados
**Status:** concluído na época · em 24/09 22:02 o servidor voltou a ligar pelo SSD antigo, ver
`2026-10-incidente-boot-ssd-antigo.md`
**Relatório ao cliente:** enviado em 25/09 · pago

## Tempo

| Etapa | Data / horário | Duração |
|---|---|---|
| Checagem, backup e clonagem | 24/09, 17:30 – 22:00 | 4h30 |
| Banco de dados não subia | 25/09, horários quebrados | 1h00 |
| **Total cobrado** | | **5h30 (R$ 275,00 a R$ 50/h)** · já pago |

## 24/09 — Migração

- Levantamento dos discos, partições, volumes e espaço ocupado.
- Localização do banco do IOB Office (PostgreSQL).
- Backup completo do banco no HD externo antes de qualquer mudança.
- Conferência de que não havia BitLocker ativo.
- Clone do disco inteiro para o NVMe 2 TB.
- Testes de boot, do banco e do IOB Office pelo disco novo.
- O SSD antigo foi desconectado, mas ficou dentro da máquina como reserva, sem formatar.

## 25/09 — Folhamatic sem conexão com o banco

- Causa: sumiu de novo a pasta temporária que o banco usa ao iniciar. Ele tentava subir,
  falhava no fim e desligava.
- Análise dos logs do banco, recriação da pasta (nenhum dado alterado), conferência da estrutura
  do banco e recuperação automática concluída.
- Folhamatic abrindo normalmente. Última movimentação no banco: 24/09 18:56, antes da
  manutenção. Nada perdido.

## Recomendações deixadas

- Reiniciar o servidor uma vez, fora do horário de uso, para ver se o banco sobe sozinho.
- Manter o SSD antigo na máquina por alguns dias como segurança.

> Lição (vista em outubro): o SSD antigo ficou na máquina pronto para dar boot. Foi isso que
> permitiu o servidor voltar a ligar por ele sem ninguém notar.
