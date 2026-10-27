# 2026-10-27 — Servidor não ligava, nobreak errado e dois aparelhos com o endereço do roteador

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia (Thaís e Ângelo informados)
**Atendimento:** presencial 10:30 – 13:30 · remoto depois (horário [DEFINIR])
**Status:** 🟡 servidor e internet funcionando · contábil com erro · aparelho duplicado na rede ainda ativo

## Tempo

| Etapa | Horário | Duração |
|---|---|---|
| Presencial | 10:30 – 13:30 | 3h00 |
| Remoto (Débora, contábil) | [DEFINIR] | [DEFINIR] |
| **Total cobrado** | | **3h00 + remoto [DEFINIR]** |

## 1. Nobreak errado

O servidor **não estava no nobreak NHS 1200 VA** avaliado em 29/09, e sim num nobreak bem menor, que
não aguenta a carga. Trocado no dia. Provável causa de boa parte dos desligamentos (mais de 10 desde
25/09). Desde quando estava assim: [VERIFICAR].

## 2. Servidor não iniciava

- Tela de recuperação do Windows, erro `0xc0000001`.
- A BIOS tinha voltado ao padrão de novo: armazenamento em **RAID On** (mesmo caso de 20/09) e data
  errada. Corrigido para **AHCI** e o Windows subiu.
- Data do Windows corrigida à mão (com a data errada, sites e sincronização de hora falhavam).
- Causa: bateria CR2032 da placa-mãe fraca + desligamentos. **Troca da bateria segue pendente.**

## 3. Servidor sem internet: dois aparelhos respondendo como 192.168.0.1

**Sintoma:** servidor sem alcançar o roteador (ping e TCP), mas falando normalmente com as estações.
O ER605 também não alcançava o servidor. Reiniciar o ER605 e trocar o IP do servidor não resolveram.

**Causa encontrada:** o servidor tinha o 192.168.0.1 associado ao MAC `50-91-E3-3F-00-51`, e uma
estação com internet tinha o MAC `98-BA-5F-AB-E3-54`. São dois equipamentos TP-Link diferentes (faixas
de MAC diferentes) usando o mesmo endereço. Quem fala com o `50-91-…` fica sem internet. Explica o
"uns computadores funcionam e outros não" de 22/10.

**Hipótese:** antes de 13/10 o ER605 usava `192.168.100.x`. O reset de fábrica de 13/10 voltou o ER605
para `192.168.0.1`, que também é o endereço de fábrica do roteador Wi-Fi TP-Link. Desde então os dois
disputam o endereço. [VERIFICAR] qual aparelho tem o MAC `50-91-E3-3F-00-51`.

**Paliativo aplicado (desfazer depois):** entrada ARP permanente para o gateway com o MAC do ER605.
- Servidor: `New-NetNeighbor -InterfaceAlias Ethernet -IPAddress 192.168.0.1 -LinkLayerAddress 98-BA-5F-AB-E3-54 -State Permanent`
- Máquina da Débora: `02-tecnico/rede/corrigir-internet.bat`, executado pela Natalia.
- Para desfazer: `Remove-NetNeighbor -IPAddress 192.168.0.1 -Confirm:$false`

**Mudanças na rede do servidor:**
- O servidor estava em **DHCP com reserva**, e não com IP fixo na placa como registrado em 20/10.
  Adicionar um IP manual desligou o DHCP e derrubou o .101 por alguns minutos; DHCP reativado.
- Reserva do servidor no ER605 trocada de `.101` para **`.200`**. As estações acessam pelo nome
  (`\\AC-SERVIDOR`) e continuaram funcionando.
- Rede do servidor tinha sido marcada como `Public` por engano durante o atendimento; voltou para `Private`.

## 4. Sistema: contábil não abre

- `Z:\FolhaWin\telecont\contabil.exe`: "Falha na inicialização do aplicativo devido à configuração
  lado a lado incorreta" (`0x800736b1`), nas estações e no servidor, pela Central e direto.
- A Central IOB Office aparece como **99999 – DEMONSTRAÇÃO** (código do escritório: 20468).
- Folha e Escrita Fiscal abrem. Log da Escrita Fiscal de 10:13 (AC-LUCAS): erro 1104 lendo
  `efiscal\forms\frm_ativ.scx`, pontual.
- Arquivos do sistema alterados no dia que chamam atenção: `atualizador\dados\ATUALIZACAO.DBF`,
  `central\temas.dll`, `fupdate\SEARCH_VERSAO.SYS`, `empresa\EGASENLFC.OCX`, `central\codigo.IDX`,
  `central\dados\perm_usu.DBF`.
- A Natalia fez a restauração das tabelas; o contábil seguiu com erro.
- **Próximo passo:** comparar `telecont\contabil.exe.config` e manifestos com a cópia em
  `G:\Backup-Noturno\arquivos\Folhamatic\` e ver o evento `SideBySide` numa estação. Restaurar arquivo
  do sistema só com o OK da IOB.

## Decisões do escritório (Natalia, após falar com Thaís e Ângelo)

- Comprar **4 computadores** (Thaís, Débora, Lucas e provavelmente Luciana). Indicação do Ângelo: Dell
  Micro, no mínimo 10ª geração, NVMe; Thaís pediu 16 GB. Sem teto de orçamento; preferência por
  durabilidade. Pesquisa enviada (OptiPlex Micro 7020/7010/7000, Dell Pro Micro, HP Pro Mini 400 G9).
- Comprar o **nobreak SMS 2000 VA** para o servidor.
- Resolver a "questão do banco SQL" com o Ângelo (detalhes [VERIFICAR]).
- Pedido de apoio ao Ângelo no fim de semana, para deixar tudo pronto até sábado à noite.

## Pendências

- [ ] Contábil (ver item 4).
- [ ] Identificar o aparelho `50-91-E3-3F-00-51` e mudar o endereço dele (ou modo Access Point, sem DHCP).
- [ ] Depois disso, remover a entrada ARP permanente no servidor e na máquina da Débora.
- [ ] Trocar a bateria CR2032 do servidor e conferir na BIOS: AHCI, data, boot pelo NVMe.
- [ ] Nobreak SMS 2000 VA com servidor, ER605, aparelho da operadora e switch.
- [ ] Remover `192.168.0.200` como IP extra, se tiver sobrado algum registro manual (o atual vem do DHCP).
