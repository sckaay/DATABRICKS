-- SCRIPT DE CRIAÇÃO DO SCHEMA BRONZE
CREATE SCHEMA IF NOT EXISTS voebem.bronze;

-- Estrutura da tabela aerodromos
CREATE TABLE voebem.bronze.aerodromos (
  icao STRING COLLATE UTF8_BINARY,
  ciad STRING COLLATE UTF8_BINARY,
  nome STRING COLLATE UTF8_BINARY,
  municipio STRING COLLATE UTF8_BINARY,
  uf STRING COLLATE UTF8_BINARY,
  municipio_servido STRING COLLATE UTF8_BINARY,
  uf_servido STRING COLLATE UTF8_BINARY,
  latitude STRING COLLATE UTF8_BINARY,
  longitude STRING COLLATE UTF8_BINARY,
  altitude STRING COLLATE UTF8_BINARY,
  situacao STRING COLLATE UTF8_BINARY,
  _ingerido_em TIMESTAMP)
USING delta
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd',
  'delta.parquet.format.version' = '2.12.0',
  'delta.parquet.format.version.afe.internal' = '2.12.0')
;

-- Estrutura da tabela codigos_operacao
CREATE TABLE voebem.bronze.codigos_operacao (
  dominio STRING COLLATE UTF8_BINARY,
  codigo STRING COLLATE UTF8_BINARY,
  descricao STRING COLLATE UTF8_BINARY)
USING delta
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd',
  'delta.parquet.format.version' = '2.12.0',
  'delta.parquet.format.version.afe.internal' = '2.12.0')
;

-- Estrutura da tabela empresas_estrangeiras
CREATE TABLE voebem.bronze.empresas_estrangeiras (
  icao STRING COLLATE UTF8_BINARY,
  sigla_iata STRING COLLATE UTF8_BINARY,
  razao_social STRING COLLATE UTF8_BINARY,
  servico STRING COLLATE UTF8_BINARY,
  cidade STRING COLLATE UTF8_BINARY,
  uf STRING COLLATE UTF8_BINARY,
  situacao STRING COLLATE UTF8_BINARY,
  _arquivo_origem STRING COLLATE UTF8_BINARY,
  _ingerido_em TIMESTAMP)
USING delta
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd',
  'delta.parquet.format.version' = '2.12.0',
  'delta.parquet.format.version.afe.internal' = '2.12.0')
;

-- Estrutura da tabela empresas_nacionais
CREATE TABLE voebem.bronze.empresas_nacionais (
  icao STRING COLLATE UTF8_BINARY,
  sigla_iata STRING COLLATE UTF8_BINARY,
  razao_social STRING COLLATE UTF8_BINARY,
  servico STRING COLLATE UTF8_BINARY,
  cidade STRING COLLATE UTF8_BINARY,
  uf STRING COLLATE UTF8_BINARY,
  situacao STRING COLLATE UTF8_BINARY,
  _arquivo_origem STRING COLLATE UTF8_BINARY,
  _ingerido_em TIMESTAMP)
USING delta
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd',
  'delta.parquet.format.version' = '2.12.0',
  'delta.parquet.format.version.afe.internal' = '2.12.0')
;

-- Estrutura da tabela vra
CREATE TABLE voebem.bronze.vra (
  icao_empresa STRING COLLATE UTF8_BINARY,
  numero_voo STRING COLLATE UTF8_BINARY,
  codigo_di STRING COLLATE UTF8_BINARY,
  codigo_tipo_linha STRING COLLATE UTF8_BINARY,
  icao_origem STRING COLLATE UTF8_BINARY,
  icao_destino STRING COLLATE UTF8_BINARY,
  partida_prevista STRING COLLATE UTF8_BINARY,
  partida_real STRING COLLATE UTF8_BINARY,
  chegada_prevista STRING COLLATE UTF8_BINARY,
  chegada_real STRING COLLATE UTF8_BINARY,
  situacao_voo STRING COLLATE UTF8_BINARY,
  codigo_justificativa STRING COLLATE UTF8_BINARY,
  _arquivo_origem STRING COLLATE UTF8_BINARY,
  _ingerido_em TIMESTAMP)
USING delta
COMMENT 'Bronze - VRA (Voo Regular Ativo) da ANAC, 12 meses (ago/2025 a jul/2026).
     Dado bruto: todas as colunas string, nenhuma linha descartada.
     Carga full refresh idempotente a partir de /Volumes/voebem/bronze/arquivos/vra/.'
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd',
  'delta.parquet.format.version' = '2.12.0',
  'delta.parquet.format.version.afe.internal' = '2.12.0')
;

