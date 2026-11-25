-- =============================================================
-- DEMONSTRAÇÃO EM TEMPO REAL
-- Simula dados novos e correções chegando da origem:
-- INSERT, UPDATE e DELETE na Bronze, reprocessamento da Silver
-- e da Gold, e comparação do ANTES x DEPOIS.
-- Executar a partir da raiz do repositório.
-- =============================================================

.print ''
.print '>>> 0. Preparando o ambiente (Bronze, Silver e Gold do zero)'
.mode trash
.read sql/01_bronze.sql
.read sql/02_silver.sql
.read sql/03_gold.sql
.mode duckbox

-- -------------------------------------------------------------
.print ''
.print '>>> ANTES: resumo da Gold'
SELECT
    count(*)                                        AS vendas,
    sum(valor_total)                                AS faturamento,
    (SELECT count(*) FROM silver.vendas_rejeitadas) AS rejeitadas
FROM gold.fato_vendas;

.print '>>> ANTES: compras da dupla (Gabriel e Enzo)'
SELECT c.nome AS cliente, p.nome AS produto, t.data, f.valor_total
FROM gold.fato_vendas f
JOIN gold.dim_cliente c ON c.sk_cliente = f.sk_cliente
JOIN gold.dim_produto p ON p.sk_produto = f.sk_produto
JOIN gold.dim_tempo   t ON t.sk_tempo   = f.sk_tempo
WHERE c.id_cliente IN (1, 2);

-- -------------------------------------------------------------
.print ''
.print '>>> 1. INSERT: chegam 4 vendas novas (uma delas com quantidade 0)'
INSERT INTO bronze.vendas
    (id_venda, data_venda, id_cliente, id_produto, quantidade, valor_unitario, arquivo_origem, carregado_em)
VALUES
    ('40', '2026-11-24', '1', '108', '1', '2799.00', 'demo_ao_vivo', current_timestamp),
    ('41', '2026-11-24', '2', '104', '1', '1299.00', 'demo_ao_vivo', current_timestamp),
    ('42', '2026-11-24', '1', '107', '2', '89.90',   'demo_ao_vivo', current_timestamp),
    ('43', '2026-11-24', '2', '103', '0', '129.90',  'demo_ao_vivo', current_timestamp);

SELECT id_venda, data_venda, id_cliente, id_produto, quantidade, valor_unitario
FROM bronze.vendas
WHERE arquivo_origem = 'demo_ao_vivo';

.print '>>> 2. UPDATE: o Headset (106) ganha a categoria que estava faltando'
UPDATE bronze.produtos
SET categoria = 'Periféricos'
WHERE id_produto = '106';

SELECT id_produto, nome, categoria FROM bronze.produtos WHERE id_produto = '106';

.print '>>> 3. DELETE: o Gabriel cancelou a compra do mousepad (venda 42)'
DELETE FROM bronze.vendas
WHERE id_venda = '42';

SELECT id_venda, id_cliente, id_produto, quantidade
FROM bronze.vendas
WHERE arquivo_origem = 'demo_ao_vivo';

-- -------------------------------------------------------------
.print ''
.print '>>> 4. Reprocessando Silver e Gold'
.mode trash
.read sql/02_silver.sql
.read sql/03_gold.sql
.mode duckbox

-- -------------------------------------------------------------
.print ''
.print '>>> DEPOIS: resumo da Gold'
SELECT
    count(*)                                        AS vendas,
    sum(valor_total)                                AS faturamento,
    (SELECT count(*) FROM silver.vendas_rejeitadas) AS rejeitadas
FROM gold.fato_vendas;

.print '>>> DEPOIS: compras da dupla (Gabriel e Enzo)'
SELECT c.nome AS cliente, p.nome AS produto, t.data, f.valor_total
FROM gold.fato_vendas f
JOIN gold.dim_cliente c ON c.sk_cliente = f.sk_cliente
JOIN gold.dim_produto p ON p.sk_produto = f.sk_produto
JOIN gold.dim_tempo   t ON t.sk_tempo   = f.sk_tempo
WHERE c.id_cliente IN (1, 2);

.print '>>> DEPOIS: a venda com quantidade 0 foi barrada pela Silver'
SELECT id_venda, id_cliente, quantidade, motivo
FROM silver.vendas_rejeitadas
WHERE id_venda = 43;

.print '>>> DEPOIS: faturamento por categoria (sem "Sem categoria")'
SELECT p.categoria, sum(f.valor_total) AS faturamento
FROM gold.fato_vendas f
JOIN gold.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY p.categoria
ORDER BY faturamento DESC;