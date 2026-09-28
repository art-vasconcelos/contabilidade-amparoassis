# Amparo Assis Contábil – Projeto de Serviços

Projeto de **Artur Vasconcelos – Tecnologia e Dados** para o cliente **Amparo Assis Contábil**
(contato: Natalia). Reúne propostas, materiais de divulgação, planos técnicos e o histórico
de atendimentos.

---

## Mapa das pastas

| Pasta | O que tem | Para quem |
|---|---|---|
| `00-cliente/` | Ficha do cliente e descrição do ambiente de TI (servidor, máquinas, sistemas) | Interno |
| `01-historico/` | Registro de cada atendimento feito: problema, causa, solução, horas | Interno (base para casos de sucesso) |
| `02-tecnico/backup-monitoramento/` | Plano técnico de backup automático e monitoramento do servidor, com os scripts | Interno + resumo para o cliente |
| `03-propostas/servicos-gerais/` | Proposta geral: todos os serviços e formas de cobrança (hora remota, hora presencial, manutenção mensal, projeto) | Amparo |
| `03-propostas/projeto-automacao-ia/` | Proposta do primeiro projeto de automação com IA + formulário de levantamento de processos (Excel) + texto do e-mail de envio | Amparo |
| `04-cartilhas/clientes-amparo/` | Cartilha de serviços para os clientes da Amparo (pequenos comércios) | Clientes da Amparo |
| `05-modelos/` | Modelos reutilizáveis: registro de atendimento, orçamento de projeto | Interno |
| `_identidade/` | Nome, contatos e padrão visual usados em todos os documentos | Interno |

Documentos para o cliente são escritos em **HTML** (fonte, editável) e entregues em **PDF**.
Material interno fica em **Markdown**.

---

## Status dos entregáveis

| # | Entregável | Formato | Local | Status |
|---|---|---|---|---|
| 1 | Estrutura de pastas + README | Markdown | raiz | ✅ Pronto |
| 2 | Proposta geral de serviços | HTML → PDF | `03-propostas/servicos-gerais/` | ✅ Pronto |
| 3 | Proposta do projeto de automação com IA | HTML → PDF | `03-propostas/projeto-automacao-ia/` | ✅ Pronto |
| 4 | Formulário de levantamento de processos | Excel | `03-propostas/projeto-automacao-ia/` | 🟡 Em revisão |
| 5 | Texto do e-mail de envio | Markdown | `03-propostas/projeto-automacao-ia/` | ⏳ A fazer |
| 6 | Histórico dos atendimentos | Markdown | `01-historico/` | ⏳ Depois |
| 7 | Plano de backup e monitoramento | Markdown + scripts | `02-tecnico/backup-monitoramento/` | ⏳ Depois |
| 8 | Cartilha para os clientes da Amparo | HTML → PDF | `04-cartilhas/clientes-amparo/` | ⏳ Depois |

---

## Regras do projeto

Valem para todo arquivo criado aqui.

1. **Sem nomes das empresas onde o Artur trabalha nem de pessoas de lá.** Casos citados de forma
   genérica: "indústria de equipamentos", "empresa de segurança eletrônica".
2. **Sem preços ou prazos inventados.** Onde faltar valor, usar `[DEFINIR]`.
3. **Sem consultoria do sistema da folha (Folhamatic).** O serviço oferecido é o suporte de
   infraestrutura do servidor onde ele roda.
4. **Sem senhas, IDs de acesso remoto ou IPs no repositório.** Onde precisar, usar `[VER COFRE]`.
5. **Linguagem para o cliente:** simples, sem jargão técnico, focada no benefício.
6. **Dados pessoais (LGPD):** testes e pilotos usam dados de exemplo ou mascarados, nunca dados
   reais de funcionários ou clientes do escritório.
7. Tudo em **português do Brasil**.

---

## Marcadores usados nos documentos

| Marcador | Significado |
|---|---|
| `[DEFINIR]` | Valor, prazo ou condição que o Artur precisa preencher |
| `[VERIFICAR]` | Informação a confirmar no próximo acesso ao cliente |
| `[VER COFRE]` | Dado sensível guardado fora do repositório |
