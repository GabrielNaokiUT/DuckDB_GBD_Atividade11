-- =============================================================
-- EXPORTAÇÃO DA GOLD PARA PARQUET
-- Grava as tabelas do Star Schema em arquivos Parquet (formato
-- colunar aberto, usado em Data Lakes e Lakehouses) e depois
-- consulta os arquivos direto, sem usar as tabelas do banco.
-- Executar depois do 03_gold.sql.
-- =============================================================

-- Exportação (a pasta dados/gold já existe no repositório)
COPY gold.dim_cliente TO 'dados/gold/dim_cliente.parquet' (FORMAT parquet);
COPY gold.dim_produto TO 'dados/gold/dim_produto.parquet' (FORMAT parquet);
COPY gold.dim_tempo   TO 'dados/gold/dim_tempo.parquet'   (FORMAT parquet);
COPY gold.fato_vendas TO 'dados/gold/fato_vendas.parquet' (FORMAT parquet);

-- Conferência: o DuckDB consulta o arquivo direto pelo caminho
SELECT 'dim_cliente.parquet' AS arquivo, count(*) AS linhas FROM 'dados/gold/dim_cliente.parquet'
UNION ALL
SELECT 'dim_produto.parquet', count(*) FROM 'dados/gold/dim_produto.parquet'
UNION ALL
SELECT 'dim_tempo.parquet', count(*) FROM 'dados/gold/dim_tempo.parquet'
UNION ALL
SELECT 'fato_vendas.parquet', count(*) FROM 'dados/gold/fato_vendas.parquet';

-- Consulta lendo SOMENTE os arquivos Parquet
SELECT
    t.nome_mes,
    sum(f.valor_total) AS faturamento
FROM read_parquet('dados/gold/fato_vendas.parquet') f
JOIN read_parquet('dados/gold/dim_tempo.parquet')   t ON t.sk_tempo = f.sk_tempo
GROUP BY t.mes, t.nome_mes
ORDER BY t.mes;