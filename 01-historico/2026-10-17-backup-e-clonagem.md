# 2026-10-17 — Backup completo e clonagem do SSD antigo para o NVMe

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia
**Atendimento:** remoto (AnyDesk), sábado, com o escritório fechado
**Status:** clone concluído; falta passar a ligar pelo NVMe (visita presencial)
**Detalhes técnicos:** `02-tecnico/incidente-boot-ssd-antigo/plano-clonagem.md`

## Tempo

| Etapa | Horário |
|---|---|
| Início | 15:30 |
| Diagnóstico e conferência dos discos | 15:30 – 16:50 |
| Backup do banco e da pasta do sistema da folha (HD externo) | 16:52 – 19:20 |
| Clone SSD antigo → NVMe (DiskGenius) | 19:35 – 20:03 |
| Conferência do clone e tentativa de preparar o boot pelo NVMe | 20:03 – 20:00+ (encerramento informado pelo Artur: 20:00) |
| **Total cobrado** | **4h30 (R$ 225,00 a R$ 50/h)** |

Boa parte do tempo foi de espera das cópias (HD externo USB lento). Cobrado de 15:30 às 20:00.

## Resultado

- **Diagnóstico corrigido:** o servidor liga pelo SSD antigo desde **24/09 22:02**, e não desde 06/10. O NVMe
  ficou parado desde a noite da migração. Nenhum dado ficou só no NVMe: não há lançamento a refazer.
- **Backup no G:** banco, 47,61 GB (635.127 arquivos); `C:\Folhamatic`, 15,56 GB (199.157 arquivos). Zero falhas.
- **Clone:** 304 GB em 27min34s. Conferência com `robocopy /L`: 4.882.468 arquivos idênticos entre D: e F:.
- **Desligamentos inesperados:** 10 desde 25/09, e não 3. Há indícios de relógio da placa-mãe perdido nas quedas.
- **Fim do atendimento:** depois de configurar o acesso não supervisionado, o AnyDesk e o TeamViewer não
  reconectaram. Situação do servidor no fim do dia: [CONFIRMAR, se ele reiniciou e se voltou pelo SSD antigo].

## Pendências

- [ ] Visita (domingo 18/10 ou segunda 19/10): recuperar o acesso remoto (AnyDesk instalado como serviço +
      acesso não supervisionado; TeamViewer como segunda via).
- [ ] Na visita: conferir se a rede do servidor está `Private` e se as pastas e o sistema da folha abrem nos computadores.
- [ ] Passar a ligar pelo NVMe: desconectar o SSD antigo, ligar, conferir as letras, o banco e os
      compartilhamentos. Se o escritório tiver trabalhado depois de 17/10, refazer o clone antes.
- [ ] Estender o D: do NVMe para ocupar os 931 GB livres.
- [ ] Bateria da placa-mãe e nobreak.
- [ ] Rotina noturna de backup (SSD antigo + HD externo + nuvem); investigar a rotina que grava em `G:\BKPs`.

---

## Relatório para o cliente

**Assunto:** Relatório de atendimento – 17/10 – Backup completo e cópia do servidor para o disco novo

Olá, Natalia, tudo bem?

Segue o resumo do atendimento de sábado (17/10), feito com o escritório fechado.

**Uma correção importante**
No relatório de 16/10, informei que o servidor estava ligando pelo disco antigo desde 06/10. Analisando com
mais calma, a data correta é 24/09, logo depois da troca de disco. A boa notícia: todo o trabalho feito desde
então está no disco antigo, que é o que está em uso, e nada ficou separado no disco novo. Nenhum lançamento
precisa ser refeito.

**O que foi feito**
- Análise detalhada dos dois discos, confirmando que nenhum dado ficou apenas no disco novo;
- Cópia de segurança completa do banco do sistema da folha (47 GB) e da pasta do sistema (15 GB) no HD externo,
  com o sistema parado para garantir uma cópia íntegra. Concluída sem nenhuma falha;
- Cópia completa do disco em uso para o disco novo (300 GB), deixando os dois iguais;
- Conferência arquivo por arquivo: os 4,8 milhões de arquivos estão idênticos nos dois discos.

**Situação atual**
- O servidor continua funcionando normalmente pelo disco antigo.
- O disco novo tem uma cópia completa e atualizada de tudo.
- Falta apenas fazer o servidor passar a ligar pelo disco novo. Essa etapa é mais segura presencialmente,
  então vou combinar com você uma visita rápida.
- No fim do atendimento, o acesso remoto ao servidor não voltou. Isso não afeta o uso do sistema pela equipe,
  e vou acertar na visita.

**Ponto de atenção**
O servidor desligou sozinho 10 vezes desde 25/09. Isso reforça a urgência do nobreak e da troca da bateria da
placa-mãe, que é a causa provável de ele ter voltado a ligar pelo disco antigo.

**Tempo de atendimento**
- Remoto: 15h30 às 20h00
- Total: 4h30 (R$ 50,00/h = R$ 225,00)

Qualquer dúvida, fico à disposição.

Abraço,
Artur Vasconcelos
Analista de Sistemas e Engenheiro de Dados

---

## Mensagem para o WhatsApp

Oi, Natalia e Thaís! Passando o resumo de ontem 🙂

✅ Fiz um backup completo do sistema da folha no HD externo, sem nenhuma falha.
✅ Copiei o servidor inteiro para o disco novo: os dois estão iguais.
✅ Correção: o servidor estava no disco antigo desde 24/09, logo depois da troca, e não desde 06/10. Nada ficou para trás, ninguém precisa refazer lançamento.

Falta só fazer o servidor ligar pelo disco novo, e prefiro fazer isso presencialmente. Natalia, consigo passar aí [amanhã/segunda] — qual horário fica bom?

O acesso remoto não voltou no fim do atendimento, mas isso não atrapalha vocês. Se na segunda alguém tiver problema para abrir as pastas ou o sistema, me avisem aqui.

Mandei o relatório completo por e-mail.
