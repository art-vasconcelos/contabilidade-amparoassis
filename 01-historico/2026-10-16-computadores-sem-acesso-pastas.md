# 2026-10-16 — Computadores sem acesso às pastas do servidor

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia e Thaís
**Atendimento:** remoto (AnyDesk), com apoio do Claude Code
**Status:** resolvido (acesso às pastas) · o incidente do SSD antigo segue em andamento
**Relatório ao cliente:** enviado em 17/10 · cobrança: 1h (R$ 50,00)

## Tempo

| Etapa | Horário | Duração |
|---|---|---|
| Diagnóstico e correção remotos | 08:56 – 09:42 | 0h46 |
| **Total sugerido** | | **1h00 (R$ 50,00 a R$ 50/h)** [CONFIRMAR] |

Horário tirado das mensagens da sessão do Claude Code. Se o acesso remoto começou antes da
primeira mensagem, ajustar.

## Sintoma

- Computadores da equipe sem acesso às pastas do servidor; o sistema da folha mostrava aviso de
  falha de comunicação e o erro 1993 (arquivo `_socket.vcx` não encontrado no `Z:`).
- Relato da Thaís: no dia do problema a rede pelo cabo parou e só o Wi-Fi funcionava; após
  reinício do servidor, os computadores levam cerca de 5 minutos para ver o mapeamento.

## Diagnóstico

| Teste | Resultado | Leitura |
|---|---|---|
| `net use` | `Z:` → pasta do sistema no servidor | Mapeamento OK |
| Conexão com a IOB (80 e 443) | OK | Internet normal |
| `Get-SmbShare` | Compartilhamentos presentes | Servidor compartilhando normalmente |
| `Get-NetConnectionProfile` | **`Public`** | Firewall bloqueando o compartilhamento de pastas |

## Solução aplicada

```powershell
Set-NetConnectionProfile -InterfaceAlias 'Ethernet' -NetworkCategory Private
Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28502"   # Compartilhamento de arquivos e impressoras
```

Acesso liberado e equipe voltou a trabalhar.

## Causa provável

O desligamento inesperado de 16/10 (o servidor religou às 08:09 e reiniciou mais 3 vezes até
08:25). Depois de um reinício assim, o Windows pode não reconhecer a rede e classificá-la como
`Public`. A troca de faixa da LAN no reset do ER605 (13/10) foi descartada como causa: ao fim
da visita de 13/10 o acesso às pastas foi validado em todas as máquinas.

## Achados do mesmo atendimento

- O servidor está ligando pelo **SSD antigo desde 06/10 20:32**; a reativação do NVMe em 11/10
  não chegou a valer.
- Três desligamentos inesperados em uma semana (09, 13 e 16/10).
- `_socket.vcx` ausente nos dois discos: o erro 1993 era efeito da rede bloqueada.

Detalhes e próximos passos: `2026-10-incidente-boot-ssd-antigo.md`.

---

## Relatório enviado ao cliente

**Assunto:** Relatório de atendimento – 16/10 – Computadores sem acesso às pastas do servidor

Olá, Natalia, tudo bem?

Segue o resumo do atendimento de sexta-feira (16/10) sobre a falha de acesso às pastas do servidor.

**O problema**
Os computadores da equipe não conseguiam abrir as pastas do servidor, e o sistema da folha mostrava erro ao abrir. O servidor e a internet estavam funcionando normalmente.

**O que foi feito**
- Diagnóstico remoto via AnyDesk: testes de conexão com o servidor, com a internet e com o servidor de licenças do sistema da folha;
- Identificação da causa: o servidor desligou sozinho na sexta de manhã e, ao religar, o Windows passou a tratar a rede do escritório como uma "rede pública". Nesse modo, ele bloqueia por segurança o compartilhamento de pastas com os outros computadores;
- Correção da configuração de rede e liberação do compartilhamento no servidor;
- Validação do acesso pelos computadores da equipe;
- Verificação do estado geral do servidor, que trouxe dois pontos de atenção (abaixo).

**Resultado**
Acesso às pastas e ao sistema restabelecido em todos os computadores.

**Pontos de atenção**
- Desde 06/10, o servidor está ligando pelo disco antigo, que ficou como reserva da troca, e não pelo disco novo. Nenhum dado foi perdido: o trabalho desses dias está no disco antigo, e o que foi feito antes de 06/10 está no disco novo. Vamos juntar as duas partes com calma, combinando os horários pelo grupo.
- O servidor desligou sozinho 3 vezes na última semana (dias 09, 13 e 16). Cada desligamento desses pode causar problemas como o de sexta, por isso o nobreak e a bateria da placa-mãe ficaram urgentes.

**Tempo de atendimento**
- Remoto: 1h
- Total: 1h (R$ 50,00/h = R$ 50,00)

Qualquer dúvida, fico à disposição.

Abraço,
Artur Vasconcelos
Analista de Sistemas e Engenheiro de Dados
