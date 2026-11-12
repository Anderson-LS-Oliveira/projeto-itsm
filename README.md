# ITSM – Bronze e Banco de Destino

## Sobre o projeto

O projeto extrai dados de chamados de TI de um banco de origem, salva os arquivos no Azure Data Lake e depois carrega os dados em um banco Azure SQL.

A carga é executada automaticamente todos os dias.

## Como funciona

1. Os dados são extraídos do SQL Server.
2. Os arquivos CSV são salvos no Azure Data Lake (Bronze).
3. Uma Azure Function carrega os dados no banco de destino.
4. O processo é executado diariamente às 06:00 UTC (03:00 em Brasília).

## Tecnologias utilizadas

- Python
- SQL Server
- Azure Data Lake
- Azure SQL Database
- Azure Functions
- Git e GitHub

## Estrutura do projeto

```text
extracao/     Arquivos de extração
banco/        Scripts de criação das tabelas
funcao/       Código da Azure Function
evidencias/   Prints e resultados
```

## Atividades realizadas

**1. Extração dos dados**

Foi criado um script Python para extrair 10 tabelas do banco de origem e salvar os dados em arquivos CSV no Azure Data Lake.

**2. Criação das tabelas**

Foram criadas 10 tabelas no banco de destino, utilizando o script SQL fornecido pelo professor como base.

**3. Carga dos dados**

Foi criada uma Azure Function que executa diariamente e carrega os dados do Bronze para o banco de destino.

O processo atualiza os registros existentes e adiciona os novos, evitando duplicações.

**4. Indicadores**

Foram definidos os seguintes indicadores para o projeto:

- Total de chamados;
- Chamados por analista;
- Chamados por mês;
- Chamados por prioridade;
- Chamados por status;
- Chamados por fila;
- Tempo médio de resolução;
- Chamados com SLA estourado;
- Média de satisfação por analista (CSAT).

## Variáveis de ambiente

As informações de conexão com os bancos e o Azure Storage são configuradas por variáveis de ambiente, sem deixar senhas diretamente no código.

## Como executar

1. Instalar o Python e o ODBC Driver 18.
2. Instalar as bibliotecas necessárias:

```bash
pip install pyodbc azure-storage-blob azure-functions
```

3. Configurar as variáveis de ambiente.
4. Executar a extração:

```bash
python extract_bronze.py
```

5. Criar as tabelas:

```bash
python run_ddl.py
```

A carga dos dados acontece automaticamente pela Azure Function após a publicação.

## Resultado

Quantidade de registros carregados no banco de destino:

| Tabela | Registros |
|---|---:|
| categoria | 11 |
| cliente_organizacao | 8 |
| fila | 10 |
| sla | 9 |
| analista | 20 |
| solicitante | 20 |
| chamado | 225 |
| chamado_sla | 225 |
| chamado_status_historico | 400 |
| csat_avaliacao | 26 |
