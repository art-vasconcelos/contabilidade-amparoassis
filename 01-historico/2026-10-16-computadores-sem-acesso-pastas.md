# 2026-10-16 — Computadores sem acesso às pastas do servidor

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia e Thaís
**Atendimento:** remoto (AnyDesk), com apoio do Claude Code
**Status:** resolvido (acesso às pastas) · o incidente do SSD antigo segue em andamento
**Relatório ao cliente:** [PENDENTE] · cobrança: [PENDENTE]

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

O reset de fábrica do ER605 em 13/10 mudou a faixa da rede (de `192.168.100.x` para
`192.168.0.x`). Para o Windows do servidor, isso é uma "rede nova", que por padrão entra como
`Public`. Os desligamentos inesperados (09, 13 e 16/10) também podem causar isso, mas a troca
de faixa é a explicação mais direta.

## Achados do mesmo atendimento

- O servidor está ligando pelo **SSD antigo desde 06/10 20:32**; a reativação do NVMe em 11/10
  não chegou a valer.
- Três desligamentos inesperados em uma semana (09, 13 e 16/10).
- `_socket.vcx` ausente nos dois discos: o erro 1993 era efeito da rede bloqueada.

Detalhes e próximos passos: `2026-10-incidente-boot-ssd-antigo.md`.

---

## Relatório para o cliente (rascunho)

**Assunto:** Relatório de atendimento – 16/10 – Computadores sem acesso às pastas do servidor

Olá, Natalia, tudo bem?

Segue o resumo do atendimento de sexta-feira (16/10) sobre a falha de acesso às pastas do
servidor.

**O problema**
Os computadores da equipe não conseguiam abrir as pastas do servidor, e o sistema da folha
mostrava erro ao abrir, embora o servidor e a internet estivessem funcionando.

**O que foi feito**
- Diagnóstico remoto via AnyDesk: testes de conexão com o servidor, com a internet e com o
  servidor de licenças do sistema da folha;
- Identificação da causa: o Windows do servidor passou a tratar a rede do escritório como uma
  "rede pública" e, nesse modo, bloqueia o compartilhamento de pastas. Isso acontece quando ele
  entende que está em uma rede nova, como depois da troca de configuração do roteador ou de um
  desligamento inesperado;
- Correção da configuração de rede e liberação do compartilhamento no servidor;
- Validação do acesso pelos computadores da equipe;
- Levantamento do estado do servidor, que trouxe dois pontos de atenção (abaixo).

**Resultado**
Acesso às pastas e ao sistema restabelecido em todos os computadores.

**Pontos de atenção**
- Desde 06/10, o servidor está ligando pelo disco antigo, que ficou como reserva da troca, e não
  pelo disco novo. Nenhum dado foi perdido: o trabalho desses dias está no disco antigo, e o que
  foi feito antes de 06/10 está no disco novo. Vamos juntar as duas partes com calma, combinando
  pelo grupo.
- O servidor desligou sozinho 3 vezes na semana (dias 09, 13 e 16). Isso deixa o nobreak e a
  bateria da placa-mãe urgentes.

**Tempo de atendimento**
- Remoto: 1h
- Total: 1h (R$ 50,00/h = R$ 50,00)

Qualquer dúvida, fico à disposição.

Abraço,
Artur Vasconcelos
Analista de Sistemas e Engenheiro de Dados
