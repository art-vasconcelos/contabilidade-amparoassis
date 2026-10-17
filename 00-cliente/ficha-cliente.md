# Ficha do cliente – Amparo Assis Contábil

## Dados gerais

| Campo | Valor |
|---|---|
| Cliente | Amparo Assis Contábil |
| Ramo | Escritório de contabilidade |
| Região | São Roque/SP e região |
| Contato principal | Natalia |
| Início do relacionamento | [DEFINIR] |

## Condições combinadas

| Item | Combinado |
|---|---|
| Valor por hora (remoto) | R$ 50,00 |
| Atendimento | Remoto via AnyDesk; presencial quando necessário (Artur mora perto) |
| Valor por hora (presencial) | R$ 50,00 |
| Manutenção mensal | R$ 100 a R$ 250/mês (2 a 5 h) · mínimo R$ 100 em mês só de conferência |
| Projetos | Orçados e enviados para aprovação antes de qualquer execução |
| Pagamento | Pix (histórico); nota fiscal disponível quando necessário |
| Backup em nuvem | As responsáveis já demonstraram interesse em uma cópia na nuvem |

## Contexto

- O suporte técnico era feito por um profissional de São Paulo. A Amparo quer passar esse
  suporte para o Artur por proximidade e para evitar custo de deslocamento.
- A Natalia pretende repassar serviços do Artur para os clientes dela: sites, análise de dados
  e aplicativos. Nos documentos, não tratar esses clientes como "pequenos comércios".
- Interesse atual: automatizar processos da contabilidade usando agentes de IA ou automações
  mais simples (n8n, rotinas na própria máquina).

## Ambiente de TI (resumo)

| Item | Situação |
|---|---|
| Servidor | Dell OptiPlex · Windows 10 · disco NVMe 2 TB (migrado de SSD SATA 1 TB) |
| Sistema da folha | Folhamatic FolhaWin (fora do escopo de consultoria; suporte só à infraestrutura) |
| Banco de dados | PostgreSQL 10 |
| Backup | HD externo Seagate Expansion 2 TB (USB, letra G:, rótulo "Thaís"), ligado direto no servidor. É o backup do escritório (confirmado em 17/10/2026). 925 GB usados; o que ele guarda e com que rotina: [VERIFICAR]. Cópia lenta (cerca de 0,8 GB/min) |
| Estações | Cerca de 10 computadores, além do servidor |
| Acesso remoto | AnyDesk · IDs [VER COFRE] |
| Rede do servidor | IP 192.168.0.101 por DHCP (roteador 192.168.0.1) · reserva de IP: [VERIFICAR] · tipo de rede deve ser `Private` |
| Sistema operacional | Barra de tarefas aparenta Windows 11: confirmar com `winver` [VERIFICAR] |

## Riscos já identificados

1. **Sem rotina confirmada de backup do banco.** O HD externo existe, mas não se sabe se ele
   recebe uma cópia confiável do banco. [VERIFICAR]
2. **Backup em HD sempre ligado.** Um vírus, um pico de energia ou uma exclusão por engano
   atingem o servidor e o backup ao mesmo tempo. Falta uma cópia fora do servidor.
3. **Sem monitoramento do servidor.** Os problemas só aparecem quando o sistema para.
4. **Windows 10 sem suporte** desde outubro de 2025: não recebe mais atualizações de segurança.
5. **PostgreSQL 10 sem suporte** desde novembro de 2022. A troca de versão depende do fornecedor
   do sistema da folha; registrar e não mexer sem a aprovação dele.
6. **Dois clones prontos para dar boot na mesma máquina.** Em out/2026 o servidor subiu pelo
   SSD antigo depois de uma queda de energia. Ver `01-historico/2026-10-incidente-boot-ssd-antigo.md`.
7. **Desligamentos inesperados frequentes** (09, 13 e 16/10/2026). **Sem nobreak, e bateria
   da placa-mãe possivelmente fraca.** Os dois estão em compra pelo
   escritório (out/2026).

Detalhes de cada atendimento: ver `01-historico/`.

## Fora do escopo (decisão do Artur)

- **Conferência e conciliação contábil** como responsabilidade do Artur. Pode ser automatizada
  como projeto, mas a responsabilidade pela conferência continua com o escritório.
- **Consultoria de uso do sistema da folha.** O Artur faz a ponte técnica com o fornecedor
  quando necessário.
- **Cadastro de usuários**: o escritório não tem essa necessidade.
