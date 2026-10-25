# 2026-10-22 — Computadores com rede local, mas sem internet

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia e equipe
**Atendimento:** remoto, por telefone com a equipe no escritório, com apoio do Claude Code
**Status:** 🟡 resolvido no dia com reinício do roteador; a instabilidade voltou depois e segue em
investigação
**Relacionado:** `2026-10-20-troca-nvme-rede-backup.md` (reservas de IP e IP fixo do servidor)

## Tempo

| Etapa | Horário | Duração |
|---|---|---|
| Diagnóstico e correção por telefone | [CONFIRMAR] (manhã, a partir de cerca de 10:00) | cerca de 2h00 |
| **Total cobrado** | | **2h00 (R$ 100,00 a R$ 50/h)** [CONFIRMAR] |

## Sintoma

- Os computadores recebiam endereço e acessavam as pastas do servidor, mas não navegavam.
- Alguns computadores funcionavam e outros não.

## Diagnóstico

| Teste | Resultado | Leitura |
|---|---|---|
| ER605 → WAN | Conectado, recebendo endereço da ONT da operadora; DNS 8.8.8.8 e 1.1.1.1 | Saída do roteador para a internet OK |
| Máquina sem internet: `ipconfig /all` | IP fixo configurado na placa, gateway e DNS = ER605 | Configuração aparentemente certa |
| Máquina sem internet: `ping` no ER605 e em 8.8.8.8 | Falha nos dois | Não era DNS: a máquina não alcançava nem o roteador |
| Máquina que funcionava: `arp -a` | O **mesmo MAC** aparecia com **dois IPs**: o recebido antes por DHCP e o novo, fixo na placa | Causa encontrada |

**Causa:** em duas máquinas, foi colocado um IP fixo na placa, diferente do IP que o ER605 tinha
entregue a elas por DHCP e que continuava registrado no roteador. Com o mesmo MAC usando um IP
diferente do registrado, o ER605 deixa de responder à máquina. A rede local continua funcionando,
porque os computadores falam direto entre si, mas a internet, que passa pelo roteador, para.
Foi o mesmo comportamento do servidor em 20/10 (registrado no `.101`, com IP fixo no `.103`), que
também só voltou depois de reiniciar o roteador.

## Solução aplicada

1. Nas duas máquinas, a placa voltou para **automático (DHCP)**. O IP desejado passou a ser
   garantido só pela **reserva no ER605** (Network → LAN → Address Reservation).
2. Reinício do ER605, para apagar os registros antigos.
3. Renovação do IP nas máquinas, com teste de internet.
4. Resultado: os computadores voltaram a navegar.

**Regra daqui para a frente:** IP certo para um equipamento se faz pela **reserva no roteador**,
com a placa em automático. Não configurar IP fixo na placa das estações. O servidor tem IP fixo
na placa igual à reserva dele, o que mantém tudo consistente.

Conferido no mesmo dia: a central de alarme já está no endereço reservado para ela, e o endereço
que ela tomava do servidor ficou livre.

## Depois do atendimento: instabilidade voltou

Depois do reinício, a equipe relatou de novo **quedas de internet que vêm e vão sozinhas**,
afetando computadores, o servidor e a central de alarme. Como o servidor e a central já estão com
endereço consistente, a causa provavelmente é outra. Hipóteses, da mais para a menos provável:

| Hipótese | Por que é suspeita | Como confirmar |
|---|---|---|
| **Quedas de energia rápidas** derrubando ONT, ER605 e switch | O servidor já desligou sozinho 11 vezes desde 25/09, sem nobreak. Os equipamentos de rede também não têm nobreak e reiniciam em 1 a 2 minutos | Tempo ligado (uptime) do ER605 e da ONT logo depois de uma queda; monitor de conexão mostra "SEM ROTEADOR" |
| **Link entre o ER605 e a ONT da operadora** caindo | ER605 depende do endereço que a ONT entrega | Log do sistema do ER605 (WAN down/up); monitor mostra "ROTEADOR SEM ONT" ou "OPERADORA SEM INTERNET" |
| **Outra máquina com IP fixo** em conflito, ou outro aparelho distribuindo IP | Mesmo padrão de 22/10 | Lista de clientes DHCP do ER605 e `arp -a` comparados |
| **Laço de cabo no switch** ou equipamento com defeito | Derruba todos ao mesmo tempo, de forma intermitente | Luzes do switch piscando todas juntas; teste desligando cabos |
| **Firmware antigo do ER605** (v2.20) | Já teve falha de DNS em 13/10 | Atualizar pelo site da TP-Link |

**Ferramenta preparada:** `02-tecnico/rede/monitor-conexao.ps1`. Roda no servidor como tarefa,
testa a cada 30 segundos placa → roteador → ONT → internet → DNS, e registra em
`C:\Suporte\rede\eventos-AAAA-MM.log` cada queda, com a hora, a duração e o trecho onde quebrou.

## Pendências

- [ ] Instalar o monitor de conexão no servidor (`.\monitor-conexao.ps1 -Instalar`) e, se
      possível, também em uma estação, para comparar.
- [ ] Depois de alguns dias, ou logo depois de uma queda, ler `eventos-*.log` e conferir o tempo
      ligado do ER605 (Status) e o log do sistema dele (System Tools → System Log).
- [ ] Conferir se o firmware do ER605 tem atualização.
- [ ] Nobreak também para a ONT, o ER605 e o switch, além do servidor.
- [ ] Revisar as estações: nenhuma com IP fixo na placa.

---

## Relatório para o cliente

**Assunto:** Relatório de atendimento – 22/10 – Computadores sem internet

Olá, Natalia, tudo bem?

Segue o resumo do atendimento de quarta-feira (22/10), feito por telefone com vocês no escritório.

**O que aconteceu**
Os computadores acessavam as pastas do servidor, mas alguns não conseguiam navegar na internet.

**Causa**
Em duas máquinas, o endereço de rede tinha sido configurado manualmente no próprio computador,
diferente do endereço que o roteador tinha registrado para elas. Quando isso acontece, o roteador
deixa de "responder" a essas máquinas: a rede interna continua funcionando, mas a internet não.

**O que foi feito**
- As duas máquinas voltaram para a configuração automática, e o endereço de cada uma ficou
  reservado direto no roteador, que é a forma correta de fazer;
- O roteador foi reiniciado e as máquinas voltaram a navegar.

**Ponto de atenção**
Depois disso, vocês perceberam de novo quedas de internet que vêm e voltam sozinhas, afetando
também o servidor e o alarme. Como a causa parece ser outra, vou instalar no servidor uma
ferramenta que fica testando a conexão o tempo todo e registra cada queda: a hora, quanto tempo
durou e em que ponto a conexão quebrou (no roteador, no aparelho da operadora ou na própria
internet). Com esse registro, a gente para de tentar adivinhar e corrige a causa certa.

Uma das suspeitas é energia: o servidor já desligou sozinho várias vezes, e o roteador e o
aparelho da operadora também não estão no nobreak. **Quando o nobreak chegar, vale ligar neles
também.**

**Tempo de atendimento**
- Remoto (por telefone): cerca de 2h
- Total: 2h (R$ 50,00/h = R$ 100,00)

Qualquer dúvida, fico à disposição.

Abraço,
Artur Vasconcelos
Analista de Sistemas e Engenheiro de Dados

---

## Mensagem para o WhatsApp

Oi, Natalia! Resumo do atendimento de quarta (22/10) 🙂

✅ Achamos a causa dos computadores sem internet: duas máquinas estavam com o endereço de rede configurado na mão, diferente do que o roteador tinha registrado. Deixei as duas no automático, com o endereço reservado no roteador, e reiniciamos.

⚠️ Vocês comentaram que a internet voltou a cair e voltar sozinha, inclusive no servidor e no alarme. Vou deixar uma ferramenta no servidor registrando cada queda (hora, duração e onde quebrou), para atacar a causa certa.

💡 Quando o nobreak chegar, vale ligar nele também o roteador e o aparelho da operadora, além do servidor.

Se cair de novo, me avisem a hora aproximada que ajuda na análise.

Mandei o relatório completo por e-mail.
