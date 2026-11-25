@echo off
REM =============================================================
REM ORQUESTRACAO DO PIPELINE (Windows)
REM Roda as camadas na ordem: Bronze -> Silver -> Gold -> Parquet.
REM Para se alguma etapa der erro.
REM =============================================================
chcp 65001 > nul
cd /d "%~dp0"

where duckdb > nul 2> nul
if errorlevel 1 (
    echo [ERRO] DuckDB nao encontrado. Instale com: winget install DuckDB.cli
    exit /b 1
)

if exist loja.duckdb del /q loja.duckdb
if exist loja.duckdb.wal del /q loja.duckdb.wal

echo.
echo [1/4] Camada Bronze - ingestao dos dados brutos
duckdb loja.duckdb -f sql/01_bronze.sql || goto erro

echo.
echo [2/4] Camada Silver - limpeza e padronizacao
duckdb loja.duckdb -f sql/02_silver.sql || goto erro

echo.
echo [3/4] Camada Gold - modelo estrela
duckdb loja.duckdb -f sql/03_gold.sql || goto erro

echo.
echo [4/4] Exportacao da Gold para Parquet
duckdb loja.duckdb -f sql/06_exportar_parquet.sql || goto erro

echo.
echo Pipeline concluido com sucesso!
exit /b 0

:erro
echo.
echo [ERRO] O pipeline parou na etapa acima.
exit /b 1