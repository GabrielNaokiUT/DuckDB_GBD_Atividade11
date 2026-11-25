-- =============================================================
-- CAMADA BRONZE
-- Ingestão dos arquivos brutos (CSV e JSON) sem nenhum tratamento.
-- Tudo é lido como texto (VARCHAR) para guardar o dado exatamente
-- como veio da origem, com o nome do arquivo e a hora da carga.
-- Executar a partir da raiz do repositório.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS bronze;

-- Clientes (CSV)
CREATE OR REPLACE TABLE bronze.clientes AS
SELECT
    *,
    current_timestamp AS carregado_em
FROM read_csv('dados/raw/clientes.csv', all_varchar = true, filename = 'arquivo_origem');

-- Produtos (JSON)
CREATE OR REPLACE TABLE bronze.produtos AS
SELECT
    *,
    current_timestamp AS carregado_em
FROM read_json(
    'dados/raw/produtos.json',
    columns = {
        id_produto: 'VARCHAR',
        nome: 'VARCHAR',
        categoria: 'VARCHAR',
        preco: 'VARCHAR'
    },
    filename = 'arquivo_origem'
);

-- Vendas (CSV)
CREATE OR REPLACE TABLE bronze.vendas AS
SELECT
    *,
    current_timestamp AS carregado_em
FROM read_csv('dados/raw/vendas.csv', all_varchar = true, filename = 'arquivo_origem');

-- Conferência da carga
SELECT 'bronze.clientes' AS tabela, count(*) AS linhas FROM bronze.clientes
UNION ALL
SELECT 'bronze.produtos', count(*) FROM bronze.produtos
UNION ALL
SELECT 'bronze.vendas', count(*) FROM bronze.vendas;