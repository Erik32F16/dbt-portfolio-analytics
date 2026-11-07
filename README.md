# Teste técnico — Engenharia de Dados | Clube do Valor

Projeto de transformação de dados de clientes e transações de ativos com dbt e DuckDB. O resultado é uma carteira por cliente e ativo, com quantidade líquida e saldo financeiro das operações.

## Pré-requisitos

- Python 3.13 ou superior, conforme `pyproject.toml`.
- Acesso à internet para instalar as dependências Python e os pacotes dbt.
- Os arquivos `clients.csv` e `transactions.csv` na pasta `seeds/`, já incluídos no repositório.

Os comandos abaixo devem ser executados na raiz do projeto, em um terminal Bash ou Zsh (Linux/macOS).

## Instalação

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip certifi
python -m pip install poetry
poetry install --no-root
```

O argumento `--no-root` instala as dependências sem tentar instalar este projeto dbt como um pacote Python. As versões das dependências estão registradas em `poetry.lock`.

## Configuração e execução

O arquivo `profiles.yml` já configura o perfil `clube` para usar o banco local `clube.duckdb`, com quatro threads. O destino se chama `prod`, mas utiliza um arquivo local, sem serviço de banco externo.

Indique ao dbt o diretório do perfil e execute:

```sh
export DBT_PROFILES_DIR="$PWD"
dbt deps
dbt seed
dbt run
dbt test
```

- `dbt deps`: instala o pacote `dbt_utils`.
- `dbt seed`: carrega os CSVs no DuckDB.
- `dbt run`: constrói os modelos na ordem das dependências declaradas com `ref()`.
- `dbt test`: executa os testes genéricos e o teste singular de posições negativas.

Em um novo terminal, ative novamente a `.venv` e defina `DBT_PROFILES_DIR` antes de executar os comandos dbt.

### Resultado esperado dos testes

Os dados fornecidos contêm problemas intencionais de qualidade. O staging filtra registros inválidos de clientes e transações e deduplica registros por identificador, sem alterar manualmente os CSVs.

Os testes genéricos atuais verificam campos obrigatórios, unicidade, operações aceitas e valores não negativos nas colunas configuradas em `models/schema.yml`.

O mart exclui combinações de cliente e ativo com quantidade líquida negativa, usando `HAVING net_quantity >= 0`. As transações correspondentes permanecem na fato, mas essas combinações não aparecem na carteira final.

O teste singular `tests/assert_no_negative_position.sql` verifica se o mart contém alguma carteira com `net_quantity < 0`. Como essas posições são excluídas pelo modelo, o teste deve passar. Com os dados fornecidos, todos os testes devem passar e o comando `dbt test` deve terminar com código de saída zero.

## Estrutura dos modelos

```text
seeds/
  clients.csv
  transactions.csv
models/
  staging/
    stg_clients.sql
    stg_transactions.sql
  intermediate/
    int_transactions.sql
  marts/
    dim_clients.sql
    fact_transactions.sql
    mart_client_portfolio.sql
  schema.yml
macros/
  deduplicate.sql
  bookmark.sql
tests/
  assert_no_negative_position.sql
```

| Modelo | Responsabilidade |
| --- | --- |
| `stg_clients` | Converte os tipos, normaliza as UFs para maiúsculas, exclui clientes com identificador, nome ou cidade nulos, UF fora da lista válida ou data de cadastro inválida e deduplica por identificador. |
| `stg_transactions` | Converte os tipos, filtra registros inválidos e deduplica transações. |
| `dim_clients` | Mantém a dimensão de clientes com chave substituta numérica `id` e atualização incremental por `merge`. |
| `int_transactions` | Associa as transações à dimensão; seu `client_id` passa a conter `dim_clients.id`. |
| `fact_transactions` | Mantém as transações com chave substituta própria e atualização incremental por `merge`. |
| `mart_client_portfolio` | Agrega as transações por cliente e ativo e exclui combinações com quantidade líquida negativa. |

No staging e em `dim_clients`, `client_id` é o identificador de negócio do CSV, como `C1`. Em `int_transactions`, `fact_transactions` e `mart_client_portfolio`, `client_id` é a chave substituta numérica da dimensão. O relacionamento do mart usa essa chave.

O modelo intermediário usa `LEFT JOIN`, preservando transações sem cliente correspondente com chave nula. O mart usa `INNER JOIN` e inclui somente transações associadas à dimensão.

### Cálculo da carteira

- `net_quantity`: soma das quantidades de compra menos a soma das quantidades de venda.
- `position`: soma de `quantity × unit_price` nas compras menos a mesma soma nas vendas.

`position` representa o saldo financeiro das transações; não representa o valor de mercado atual da carteira.

Após a agregação, o mart mantém somente combinações com `net_quantity >= 0`. O filtro considera a quantidade líquida, não o saldo financeiro `position`.

### Carga incremental e macros

`dim_clients` faz `merge` por identificador de negócio. `fact_transactions` faz `merge` por `transaction_id`, processando transações cuja `transaction_date` seja maior ou igual à maior data já carregada. A inclusão da data limite permite reprocessar operações desse dia sem duplicar transações.

As chaves substitutas são geradas por sequências e preservadas nas atualizações incrementais. Registros novos podem receber identificadores com intervalos entre os valores.

A macro `deduplicate` é compartilhada pelos modelos de staging. A macro `bookmark` obtém a maior data carregada na fato, com uma data padrão quando necessário.

Transações atrasadas ou corrigidas com data anterior ao limite incremental exigem reconstrução completa. Após mudanças no significado ou no tipo das chaves, reconstrua todos os modelos para manter os relacionamentos consistentes:

```sh
dbt run --full-refresh
dbt test
```

Uma reconstrução completa pode gerar novas chaves substitutas. O comando acima também reconstrói os modelos dependentes.

## Documentação

As descrições dos seis modelos e de suas colunas estão em `models/schema.yml`. Para gerar e consultar a documentação do dbt:

```sh
dbt docs generate
dbt docs serve
```
