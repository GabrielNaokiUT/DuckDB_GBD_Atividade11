-- =============================================================
-- CAMADA SILVER
-- Limpeza e padronização dos dados da Bronze:
-- tipos corretos, textos padronizados, duplicados removidos
-- e vendas inválidas separadas numa tabela de rejeitadas.
-- Executar depois do 01_bronze.sql.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS silver;

-- Clientes: remove duplicados, tira espaços e padroniza cidade/UF
CREATE OR REPLACE TABLE silver.clientes AS
SELECT
    TRY_CAST(id_cliente AS INTEGER)         AS id_cliente,
    trim(nome)                              AS nome,
    lower(trim(email))                      AS email,
    CASE
        WHEN lower(trim(cidade)) = 'goiania' THEN 'Goiânia'
        ELSE trim(cidade)
    END                                     AS cidade,
    upper(trim(uf))                         AS uf,
    TRY_CAST(data_cadastro AS DATE)         AS data_cadastro
FROM bronze.clientes
QUALIFY row_number() OVER (PARTITION BY id_cliente ORDER BY carregado_em) = 1;

-- Produtos: converte o preço (troca vírgula por ponto) e trata categoria nula
CREATE OR REPLACE TABLE silver.produtos AS
SELECT
    TRY_CAST(id_produto AS INTEGER)                         AS id_produto,
    trim(nome)                                              AS nome,
    coalesce(trim(categoria), 'Sem categoria')              AS categoria,
    TRY_CAST(replace(preco, ',', '.') AS DECIMAL(10, 2))    AS preco
FROM bronze.produtos
QUALIFY row_number() OVER (PARTITION BY id_produto ORDER BY carregado_em) = 1;

-- Vendas: converte os tipos e marca o motivo de cada venda inválida
CREATE OR REPLACE TEMP TABLE vendas_validadas AS
WITH vendas AS (
    SELECT
        TRY_CAST(id_venda AS INTEGER)                AS id_venda,
        TRY_CAST(data_venda AS DATE)                 AS data_venda,
        TRY_CAST(id_cliente AS INTEGER)              AS id_cliente,
        TRY_CAST(id_produto AS INTEGER)              AS id_produto,
        TRY_CAST(quantidade AS INTEGER)              AS quantidade,
        TRY_CAST(valor_unitario AS DECIMAL(10, 2))   AS valor_unitario,
        row_number() OVER (PARTITION BY id_venda ORDER BY carregado_em) AS ocorrencia
    FROM bronze.vendas
)
SELECT
    *,
    CASE
        WHEN ocorrencia > 1                                          THEN 'venda duplicada'
        WHEN data_venda IS NULL                                      THEN 'venda sem data'
        WHEN quantidade IS NULL OR quantidade <= 0                   THEN 'quantidade inválida'
        WHEN id_cliente NOT IN (SELECT id_cliente FROM silver.clientes) THEN 'cliente inexistente'
        WHEN id_produto NOT IN (SELECT id_produto FROM silver.produtos) THEN 'produto inexistente'
    END AS motivo
FROM vendas;

-- Vendas válidas seguem para a Gold
CREATE OR REPLACE TABLE silver.vendas AS
SELECT * EXCLUDE (ocorrencia, motivo)
FROM vendas_validadas
WHERE motivo IS NULL;

-- Vendas inválidas ficam guardadas com o motivo (não são apagadas)
CREATE OR REPLACE TABLE silver.vendas_rejeitadas AS
SELECT * EXCLUDE (ocorrencia)
FROM vendas_validadas
WHERE motivo IS NOT NULL;

-- Conferência da limpeza
SELECT 'silver.clientes' AS tabela, count(*) AS linhas FROM silver.clientes
UNION ALL
SELECT 'silver.produtos', count(*) FROM silver.produtos
UNION ALL
SELECT 'silver.vendas', count(*) FROM silver.vendas
UNION ALL
SELECT 'silver.vendas_rejeitadas', count(*) FROM silver.vendas_rejeitadas;

SELECT id_venda, data_venda, id_cliente, quantidade, motivo
FROM silver.vendas_rejeitadas
ORDER BY id_venda;