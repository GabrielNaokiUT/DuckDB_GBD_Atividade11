#!/usr/bin/env bash
# =============================================================
# ORQUESTRAÇÃO DO PIPELINE (Linux / macOS)
# Roda as camadas na ordem: Bronze -> Silver -> Gold -> Parquet.
# Para se alguma etapa der erro.
# =============================================================
set -e
cd "$(dirname "$0")"

if ! command -v duckdb > /dev/null; then
    echo "[ERRO] DuckDB não encontrado. Instale em https://duckdb.org"
    exit 1
fi

rm -f loja.duckdb loja.duckdb.wal

trap 'echo; echo "[ERRO] O pipeline parou na etapa acima."' ERR

echo
echo "[1/4] Camada Bronze - ingestão dos dados brutos"
duckdb loja.duckdb -f sql/01_bronze.sql

echo
echo "[2/4] Camada Silver - limpeza e padronização"
duckdb loja.duckdb -f sql/02_silver.sql

echo
echo "[3/4] Camada Gold - modelo estrela"
duckdb loja.duckdb -f sql/03_gold.sql

echo
echo "[4/4] Exportação da Gold para Parquet"
duckdb loja.duckdb -f sql/06_exportar_parquet.sql

echo
echo "Pipeline concluído com sucesso!"