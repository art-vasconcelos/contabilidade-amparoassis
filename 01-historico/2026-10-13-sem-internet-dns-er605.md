# 2026-10-13 — Escritório sem navegação (falha de DNS no gateway ER605)

**Cliente:** Amparo Assis Contábil
**Contato:** Natalia
**Atendimento:** remoto (AnyDesk) + presencial
**Status:** resolvido
**Relatório ao cliente:** enviado em 17/10

## Tempo

| Etapa | Horário | Duração |
|---|---|---|
| Diagnóstico remoto (AnyDesk) | 09:30 – 10:30 | 1h00 |
| Visita presencial | 10:30 – 11:30 | 1h00 |
| **Total cobrado** | | **2h00 (R$ 100,00 a R$ 50/h)** |

Total arredondado para 2h. O deslocamento não está incluso.

## Sintoma

- A máquina acessada via AnyDesk (usuário `bkp`) não navegava.
- O AnyDesk funcionava normalmente, o que indica que havia saída para a internet.

## Diagnóstico

| Teste | Resultado | Leitura |
|---|---|---|
| `ping 8.8.8.8` | OK (6–7 ms, 0% perda) | Link e roteamento OK |
| `ping google.com` | "não pôde encontrar o host" | Falha de resolução de nomes |
| `ipconfig /all` | DNS = gateway (faixa `192.168.100.x`) via DHCP, sufixo `lan` | DNS entregue pelo gateway (o sufixo `lan` é padrão, irrelevante) |
| `nslookup google.com` | `Server failed` no gateway | O DNS do gateway responde, mas não resolve |
| `nslookup google.com 8.8.8.8` | Resolveu | DNS público OK |

**Conclusão:** falha de DNS no gateway. O ER605 atua como DNS da rede e repassa para o DNS
configurado na WAN, e esse repasse estava quebrado.

- O reboot dos roteadores **não resolveu**: continuou `Server failed` às 10:16.

## Equipamento

- **Gateway:** TP-Link **ER605 (UN) v2.20**, Omada Gigabit VPN Gateway.
  - Faixa padrão de fábrica: `192.168.0.x`.
  - Faixa da rede do cliente antes do reset: `192.168.100.x`.
- Antes do ER605 fica a ONT/modem da operadora, que **não foi resetada**.
- **Ninguém no escritório tinha a senha de admin do ER605.**

## Solução aplicada (presencial)

1. Com autorização do escritório, foi feito o **reset de fábrica do ER605**.
2. Após o reset, aguardado o ER605 subir e reconhecer as conexões (WAN/LAN).
3. Validado que o sistema estava funcionando normalmente.
4. Validada a conexão em **cada máquina da contabilidade**.
5. **IPv6 desabilitado nas máquinas** para simplificar a comunicação na rede.

## Consequência observada em 16/10

No atendimento de 16/10 o servidor estava em `192.168.0.x`, com o roteador na faixa de fábrica.
Ou seja, **a LAN voltou para a faixa padrão após o reset**. Para o Windows do servidor isso é
uma "rede nova", o que é a explicação mais provável para a rede ter ficado `Public` e bloqueado
o compartilhamento de pastas. Ver `2026-10-16-computadores-sem-acesso-pastas.md`.

## Pendências / pontos de atenção

- [ ] **Senha de admin do ER605:** confirmar que foi criada após o reset e guardar em local
  seguro [VER COFRE]. É a causa raiz de não ter dado para corrigir sem reset.
- [ ] **DNS da WAN do ER605:** confirmar se ficou automático (operadora) ou manual. Se voltar a
  falhar, configurar manualmente `8.8.8.8` / `1.1.1.1`.
- [x] **Faixa da LAN após o reset:** voltou para `192.168.0.x` (confirmado em 16/10).
- [ ] **IPs fixos e reservas:** conferir impressoras e qualquer equipamento com IP fixo na faixa
  antiga `192.168.100.x`; criar reserva de DHCP para o servidor.
- [ ] **IPv6 desabilitado:** registrar em quais máquinas. É um contorno, não uma necessidade; se
  algo depender de IPv6 no futuro, lembrar disso.
- [ ] **Configs perdidas no reset:** verificar se havia redirecionamento de porta ou VPN no
  ER605 (ex.: acesso externo ao servidor). O AnyDesk não depende disso.
- [ ] Repassar ao Sr. Ângelo (responsável técnico anterior) que o ER605 foi resetado, caso ele
  tivesse alguma configuração lá.
- [ ] **Lição para os próximos resets de roteador:** depois de trocar a faixa da rede, conferir
  no servidor se a rede continua `Private` (`Get-NetConnectionProfile`).

## Comandos úteis (referência)

```powershell
# diagnóstico
ping 8.8.8.8
ping google.com
nslookup google.com
nslookup google.com 8.8.8.8
ipconfig /all

# DNS manual em todos os adaptadores ativos (contorno, PowerShell admin)
Get-NetAdapter | Where-Object Status -eq 'Up' | Set-DnsClientServerAddress -ServerAddresses 8.8.8.8,1.1.1.1

# voltar DNS para automático
Get-NetAdapter | Where-Object Status -eq 'Up' | Set-DnsClientServerAddress -ResetServerAddresses
ipconfig /flushdns
```
