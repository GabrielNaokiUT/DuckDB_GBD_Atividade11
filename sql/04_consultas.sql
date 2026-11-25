-- =============================================================
-- CONSULTAS ANALÍTICAS (OLAP)
-- Relatórios em cima do Star Schema da camada Gold.
-- Executar depois do 03_gold.sql.
-- =============================================================

-- 1) Faturamento por mês
SELECT
    t.mes,
    t.nome_mes,
    count(*)            AS vendas,
    sum(f.valor_total)  AS faturamento
FROM gold.fato_vendas f
JOIN gold.dim_tempo t ON t.sk_tempo = f.sk_tempo
GROUP BY t.mes, t.nome_mes
ORDER BY t.mes;

-- 2) Faturamento por categoria (com % do total)
SELECT
    p.categoria,
    sum(f.quantidade)   AS itens_vendidos,
    sum(f.valor_total)  AS faturamento,
    round(100 * sum(f.valor_total) / sum(sum(f.valor_total)) OVER (), 1) AS percentual
FROM gold.fato_vendas f
JOIN gold.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY p.categoria
ORDER BY faturamento DESC;

-- 3) Top 5 produtos mais vendidos (por faturamento)
SELECT
    p.nome              AS produto,
    sum(f.quantidade)   AS itens_vendidos,
    sum(f.valor_total)  AS faturamento
FROM gold.fato_vendas f
JOIN gold.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY p.nome
ORDER BY faturamento DESC
LIMIT 5;

-- 4) Ranking dos 5 clientes que mais compraram
SELECT
    rank() OVER (ORDER BY sum(f.valor_total) DESC) AS posicao,
    c.nome              AS cliente,
    c.cidade,
    count(*)            AS compras,
    sum(f.valor_total)  AS total_gasto
FROM gold.fato_vendas f
JOIN gold.dim_cliente c ON c.sk_cliente = f.sk_cliente
GROUP BY c.nome, c.cidade
ORDER BY posicao
LIMIT 5;

-- 5) Faturamento por estado e cidade
SELECT
    c.uf,
    c.cidade,
    sum(f.valor_total)  AS faturamento
FROM gold.fato_vendas f
JOIN gold.dim_cliente c ON c.sk_cliente = f.sk_cliente
GROUP BY c.uf, c.cidade
ORDER BY faturamento DESC;