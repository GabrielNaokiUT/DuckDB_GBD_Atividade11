-- =============================================================
-- CAMADA GOLD
-- Modelagem dimensional (Star Schema) pronta para análise e BI:
-- 3 dimensões (cliente, produto, tempo) + 1 tabela fato (vendas).
-- Executar depois do 02_silver.sql.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS gold;

-- Dimensão Cliente (sk_cliente = chave substituta do DW)
CREATE OR REPLACE TABLE gold.dim_cliente AS
SELECT
    row_number() OVER (ORDER BY id_cliente) AS sk_cliente,
    id_cliente,
    nome,
    email,
    cidade,
    uf,
    data_cadastro
FROM silver.clientes;

-- Dimensão Produto
CREATE OR REPLACE TABLE gold.dim_produto AS
SELECT
    row_number() OVER (ORDER BY id_produto) AS sk_produto,
    id_produto,
    nome,
    categoria,
    preco AS preco_atual
FROM silver.produtos;

-- Dimensão Tempo (um registro por dia do ano de 2026)
CREATE OR REPLACE TABLE gold.dim_tempo AS
SELECT
    CAST(strftime(dia, '%Y%m%d') AS INTEGER)    AS sk_tempo,
    CAST(dia AS DATE)                           AS data,
    year(dia)                                   AS ano,
    quarter(dia)                                AS trimestre,
    month(dia)                                  AS mes,
    ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
     'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'][month(dia)] AS nome_mes,
    ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'][dayofweek(dia) + 1] AS dia_semana
FROM generate_series(DATE '2026-01-01', DATE '2026-12-31', INTERVAL 1 DAY) AS t(dia);

-- Fato Vendas (métricas + chaves das dimensões)
CREATE OR REPLACE TABLE gold.fato_vendas AS
SELECT
    v.id_venda,
    t.sk_tempo,
    c.sk_cliente,
    p.sk_produto,
    v.quantidade,
    v.valor_unitario,
    v.quantidade * v.valor_unitario AS valor_total
FROM silver.vendas v
JOIN gold.dim_tempo   t ON t.data = v.data_venda
JOIN gold.dim_cliente c ON c.id_cliente = v.id_cliente
JOIN gold.dim_produto p ON p.id_produto = v.id_produto;

-- Conferência do modelo
SELECT 'gold.dim_cliente' AS tabela, count(*) AS linhas FROM gold.dim_cliente
UNION ALL
SELECT 'gold.dim_produto', count(*) FROM gold.dim_produto
UNION ALL
SELECT 'gold.dim_tempo', count(*) FROM gold.dim_tempo
UNION ALL
SELECT 'gold.fato_vendas', count(*) FROM gold.fato_vendas;

SELECT
    count(*)         AS vendas,
    sum(quantidade)  AS itens_vendidos,
    sum(valor_total) AS faturamento_total
FROM gold.fato_vendas;