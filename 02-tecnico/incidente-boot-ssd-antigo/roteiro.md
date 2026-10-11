# Roteiro – Servidor subiu pelo SSD antigo após queda de energia

Registro do incidente: `01-historico/2026-10-incidente-boot-ssd-antigo.md`

## Situação

Depois de uma queda de energia, o servidor deu boot pelo **SSD antigo (SATA 1 TB)**, e não
pelo **SSD novo (NVMe 2 TB)**. O escritório trabalhou alguns dias no disco antigo sem perceber.
O Artur reativou o boot pelo disco de 2 TB.

Por isso, **nenhum dos dois discos tem tudo**:

| Disco | Tem | Falta |
|---|---|---|
| NVMe 2 TB (atual) | Migração → queda de energia, e tudo depois da reativação | O que foi feito nos dias em que o servidor rodou pelo SSD antigo |
| SSD antigo 1 TB | Estado do dia da migração, e os dias em que rodou depois da queda | Tudo entre a migração e a queda |

**Regra:** não copiar um disco por cima do outro antes de concluir as fases 1 a 4.

## Pedidos do Artur

1. Deixar os dois SSDs no mesmo estado → fases 1 a 5
2. Espelhar os dois toda noite → fase 5 (decisão A ou B)
3. Dar boot pelo SSD antigo só em caso extremo → fases 5 e 6

## Datas do incidente

| Momento | Data/hora |
|---|---|
| Queda de energia (início do período no SSD antigo) | [DEFINIR] (o script 01 ajuda a descobrir) |
| Reativação do boot pelo NVMe 2 TB (fim do período) | [DEFINIR] |
| Como o NVMe foi reativado (BIOS / desconectou o antigo) | [DEFINIR] |

---

## Fase 0 – Pode ser feito já, com o escritório trabalhando

- [ ] **Backup do banco atual.** O pg_dump só lê os dados e não para o sistema:
      `.\02-backup-banco-atual.ps1 -Destino E:\Backup-Banco` (trocar `E:` pela letra do HD externo).
- [ ] Pedir à Natalia uma lista do que a equipe lançou no sistema da folha durante os dias no
      SSD antigo: empresas, competências, tipo de lançamento.

## Fase 1 – Diagnóstico (só leitura)

- [ ] `.\01-diagnostico.ps1`. O resultado fica salvo em `C:\Suporte\diagnostico-*.txt`.
- [ ] Anotar: o número de cada disco no `Get-Disk`, qual deles está offline, o espaço usado
      no NVMe (precisa caber em 1 TB para a fase 5) e onde fica a pasta `data` do PostgreSQL.
- [ ] Nos eventos 6008, ver a data da queda de energia.

## Fase 2 – Deixar o SSD antigo acessível, em modo só leitura

O Windows costuma deixar um clone offline quando os dois discos estão ligados ao mesmo
tempo. Antes de colocar o SSD antigo online:

```powershell
Get-Disk                                   # anotar o número do SSD antigo (ex.: 1)
Set-Disk -Number 1 -IsReadOnly $true       # só leitura: nada é gravado nele
Set-Disk -Number 1 -IsOffline $false       # coloca online
Get-Partition -DiskNumber 1                # achar a partição do Windows (a maior)
Set-Partition -DiskNumber 1 -PartitionNumber <N> -NewDriveLetter F   # se não tiver letra
```

- Se o Windows recusar colocar o disco online em modo só leitura, por conflito de assinatura
  entre os clones, tire o modo só leitura e coloque online. O Windows troca a assinatura do
  disco antigo, e **ele deixa de dar boot até a fase 5**. Isso é esperado.
- [ ] Rodar `.\01-diagnostico.ps1 -LetraSsdAntigo F` para ver o período exato em que o
      servidor rodou pelo SSD antigo (eventos 6005 e 6006 do log do próprio disco).
- [ ] Preencher as datas na tabela acima.

## Fase 3 – Guardar o que só existe no SSD antigo

- [ ] **Banco:** copiar a pasta `data` do PostgreSQL do SSD antigo, sem iniciar o banco:
      `.\03-copiar-banco-ssd-antigo.ps1 -Origem "F:\<caminho da pasta data>" -Destino E:\Banco-SSD-Antigo`
- [ ] **Arquivos:** listar o que mudou no período:
      `.\04-arquivos-alterados.ps1 -RaizAntigo F:\ -Desde "<data da queda>" -Ate "<data da reativação>"`
- [ ] Abrir `C:\Suporte\arquivos-alterados-ssd-antigo.csv` no Excel e revisar com a Natalia:
  - **"So no SSD antigo"** e **"Antigo mais recente"**: copiar para o NVMe depois de revisar.
  - **"Atual mais recente"**: conflito. O arquivo foi mexido nos dois discos e é preciso
    decidir com a equipe qual versão vale.
  - A pasta do banco não entra nessa lista. Ela é tratada na fase 4.

## Fase 4 – Banco do sistema da folha

Não dá para juntar dois bancos PostgreSQL copiando arquivos. Os caminhos possíveis são:

| Caminho | Quando |
|---|---|
| **A equipe refaz** no sistema atual os lançamentos do período, a partir da lista da fase 0 | Poucos dias ou poucos lançamentos. Normalmente é o mais seguro |
| **O suporte do fornecedor** faz a junção, com o Artur fazendo a ponte técnica | Volume grande ou lançamentos difíceis de refazer |

- [ ] Se for preciso medir o tamanho da diferença antes de decidir: subir a cópia da fase 3
      em uma porta separada (ex.: 5433), restaurar o backup da fase 0 ao lado e comparar
      tabela por tabela. Script a preparar quando for necessário. A produção não é tocada.
- [ ] Guardar a cópia da fase 3 até a equipe confirmar que nada ficou faltando.

## Fase 5 – Igualar os discos e proteger daqui para frente

Só depois de concluir as fases 3 e 4.

**Decisão pendente: A ou B**

| | A) Clone noturno agendado | B) Imagem noturna + pg_dump (recomendado) |
|---|---|---|
| Como funciona | Programa de clonagem copia o NVMe inteiro para o SSD antigo toda noite | Ferramenta de imagem (ex.: Veeam Agent, versão gratuita) grava uma imagem do sistema no SSD antigo toda noite, mais um pg_dump diário com várias versões guardadas |
| Em emergência | Dá boot pelo SSD antigo (F12) | Restaura a imagem a partir do pen drive de recuperação |
| Risco | Os dois discos continuam dando boot, que foi o cenário deste incidente; um erro ou vírus do dia é copiado à noite | Nenhum risco de subir pelo disco errado; dá para voltar a dias anteriores |
| Custo | Programa de clonagem geralmente pago: [DEFINIR] | Ferramenta gratuita |

Condição para as duas: o espaço usado no NVMe precisa caber em 1 TB (ver fase 1).

- [ ] Fazer o clone ou a primeira imagem completa do NVMe para o SSD antigo.
- [ ] Agendar a rotina noturna (A ou B) e o pg_dump diário.
- [ ] Tirar o SSD antigo da ordem de boot pelo Windows:

```powershell
bcdedit /enum firmware        # identificar a entrada do SSD antigo (ver "description")
bcdedit /set {fwbootmgr} displayorder {<id-da-entrada-do-ssd-antigo>} /remove
```

  Fazer isso no fim do expediente, **com alguém no escritório**: se o servidor não ligar,
  a pessoa usa o F12 para escolher o NVMe. Depois de reiniciar, rodar `bcdedit /enum firmware`
  de novo para confirmar que a ordem continua a mesma.

## Fase 6 – Presencial (quando chegarem a bateria e o nobreak)

- [ ] Trocar a bateria da placa-mãe (CR2032). Bateria fraca faz a configuração da placa-mãe
      voltar ao padrão depois de uma queda de energia, que é a causa provável do incidente.
- [ ] Na configuração da placa-mãe (F2 ao ligar): NVMe em primeiro lugar, SSD antigo fora da
      ordem de boot e senha de administrador da configuração ([VER COFRE]).
- [ ] Ligar o servidor no nobreak e testar: tirar o nobreak da tomada e ver se o servidor
      continua ligado.
- [ ] Testar o boot de emergência: F12 → SSD antigo (opção A) ou pen drive de recuperação (opção B).
- [ ] Deixar uma folha de instruções curta perto do servidor: "o que fazer se o servidor não ligar".
