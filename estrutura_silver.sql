-- SCRIPT DE CRIAÇÃO DO SCHEMA SILVER
CREATE SCHEMA IF NOT EXISTS voebem.silver;

-- Estrutura da tabela aerodromos
CREATE TABLE voebem.silver.aerodromos (
  icao STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO (OACI) do aerodromo. Chave de ligacao com origem e destino do VRA.',
  ciad STRING COLLATE UTF8_BINARY COMMENT 'Codigo de identificacao do aerodromo no cadastro da ANAC.',
  nome STRING COLLATE UTF8_BINARY COMMENT 'Nome do aerodromo como publicado pela ANAC.',
  municipio STRING COLLATE UTF8_BINARY COMMENT 'Municipio onde o aerodromo esta fisicamente localizado.',
  uf_nome STRING COLLATE UTF8_BINARY COMMENT 'Nome da unidade federativa POR EXTENSO (Acre, Sao Paulo), nao a sigla: e assim que a ANAC publica.',
  municipio_servido STRING COLLATE UTF8_BINARY COMMENT 'Municipio principal atendido pelo aerodromo, que pode ser diferente do municipio onde ele fica.',
  uf_servido_nome STRING COLLATE UTF8_BINARY COMMENT 'Nome por extenso da UF do municipio servido.',
  latitude_dms STRING COLLATE UTF8_BINARY COMMENT 'Latitude em graus, minutos e segundos, como publicada pela ANAC.',
  longitude_dms STRING COLLATE UTF8_BINARY COMMENT 'Longitude em graus, minutos e segundos, como publicada pela ANAC.',
  altitude_m DOUBLE COMMENT 'Altitude do aerodromo em metros. Na origem vem com virgula decimal.',
  situacao STRING COLLATE UTF8_BINARY COMMENT 'Situacao do aerodromo no cadastro da ANAC.',
  _ingerido_em TIMESTAMP COMMENT 'Auditoria: momento da ingestao no bronze.',
  _transformado_em TIMESTAMP COMMENT 'Auditoria: momento da construcao da silver.')
USING delta
COMMENT 'Silver - espelho governado do cadastro de aerodromos publicos da ANAC. Cobre apenas aerodromos brasileiros: aeroportos estrangeiros do VRA nao constam aqui, e isso e propriedade da fonte, nao defeito.'
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
CREATE TABLE voebem.silver.codigos_operacao (
  dominio STRING COLLATE UTF8_BINARY COMMENT 'A qual coluna do VRA este codigo pertence: codigo_di ou codigo_tipo_linha.',
  codigo STRING COLLATE UTF8_BINARY COMMENT 'O codigo como aparece no VRA.',
  descricao STRING COLLATE UTF8_BINARY COMMENT 'Descricao oficial do codigo, curada da pagina de descricao de variaveis da ANAC.',
  _transformado_em TIMESTAMP COMMENT 'Auditoria: momento da construcao da silver.')
USING delta
COMMENT 'Silver - espelho da seed table de codigos de operacao (DI e tipo de linha) com as descricoes oficiais da ANAC.'
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

-- Estrutura da tabela empresas
CREATE TABLE voebem.silver.empresas (
  icao STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO de tres letras da empresa. Vazio para operadores sem codigo (aviacao agricola, taxi aereo, aeroclube).',
  sigla_iata STRING COLLATE UTF8_BINARY COMMENT 'Sigla de duas letras da empresa no padrao IATA, como publicada pela ANAC.',
  razao_social STRING COLLATE UTF8_BINARY COMMENT 'Razao social da empresa aerea. E o nome que aparece para quem consome o produto final.',
  servico STRING COLLATE UTF8_BINARY COMMENT 'Tipo de servico autorizado pela ANAC: transporte regular, nao regular, aeroagricola, taxi aereo.',
  cidade STRING COLLATE UTF8_BINARY COMMENT 'Municipio da sede ou do representante legal no Brasil.',
  uf STRING COLLATE UTF8_BINARY COMMENT 'Sigla da unidade federativa da sede.',
  situacao STRING COLLATE UTF8_BINARY COMMENT 'Situacao do registro na ANAC: ATIVA ou nao. Registro inativo permanece na tabela porque a empresa pode ter voado no periodo analisado.',
  origem_cadastro STRING COLLATE UTF8_BINARY COMMENT 'De qual dos dois cadastros da ANAC este registro veio: nacional ou estrangeira. E a coluna que preserva a fronteira entre as duas fontes depois da uniao.',
  _arquivo_origem STRING COLLATE UTF8_BINARY COMMENT 'Auditoria: arquivo CSV de origem.',
  _ingerido_em TIMESTAMP COMMENT 'Auditoria: momento da ingestao no bronze.',
  _transformado_em TIMESTAMP COMMENT 'Auditoria: momento da construcao da silver.')
USING delta
COMMENT 'Silver - cadastro unificado de empresas aereas: uniao dos dois cadastros do bronze (nacionais e estrangeiras) com a coluna origem_cadastro preservando a fonte de cada registro. Contagem igual a soma exata das duas tabelas de origem.'
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
CREATE TABLE voebem.silver.vra (
  icao_empresa STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO de tres letras da empresa aerea que operou a etapa. Chave para silver.empresas.',
  numero_voo STRING COLLATE UTF8_BINARY COMMENT 'Numero do voo divulgado pela companhia. Identificador comercial, nao numerico: pode ter zero a esquerda e se repete entre datas.',
  codigo_di STRING COLLATE UTF8_BINARY COMMENT 'Codigo de autorizacao (DI) da etapa: distingue etapa regular, extra, de retorno, charter. Descricao em silver.codigos_operacao (dominio codigo_di).',
  codigo_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Codigo do tipo de linha: N e C domesticas, I e G internacionais. Descricao em silver.codigos_operacao (dominio codigo_tipo_linha).',
  icao_origem STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aerodromo de onde a etapa partiu. Chave para silver.aerodromos - aeroportos estrangeiros nao constam no cadastro da ANAC.',
  icao_destino STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aerodromo onde a etapa pousou. Mesma observacao de cobertura da origem.',
  partida_prevista TIMESTAMP COMMENT 'Horario de partida programado pela companhia, na hora local do aeroporto de origem.',
  partida_prevista_data DATE COMMENT 'Data da partida programada, separada para facilitar analise por dia.',
  partida_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da partida programada (HH:mm), separada para analise por faixa horaria.',
  partida_real TIMESTAMP COMMENT 'Horario em que a aeronave efetivamente saiu. Nulo em voo cancelado, que nao chegou a partir.',
  partida_real_data DATE COMMENT 'Data da partida efetiva.',
  partida_real_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da partida efetiva (HH:mm).',
  chegada_prevista TIMESTAMP COMMENT 'Horario de chegada programado, na hora local do aeroporto de destino.',
  chegada_prevista_data DATE COMMENT 'Data da chegada programada.',
  chegada_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da chegada programada (HH:mm).',
  chegada_real TIMESTAMP COMMENT 'Horario em que a aeronave efetivamente pousou. Nulo em voo cancelado.',
  chegada_real_data DATE COMMENT 'Data da chegada efetiva.',
  chegada_real_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da chegada efetiva (HH:mm).',
  situacao_voo STRING COLLATE UTF8_BINARY COMMENT 'Situacao informada pela companhia: REALIZADO quando a etapa aconteceu, CANCELADO quando nao.',
  codigo_justificativa STRING COLLATE UTF8_BINARY COMMENT 'Motivo declarado do atraso. Deixou de ser exigido pela ANAC em abril de 2020 com a revogacao da IAC 1504: vem vazio em toda a janela deste projeto.',
  atraso_partida_min INT COMMENT 'Minutos entre a partida programada e a partida efetiva. Positivo e atraso, negativo e antecipacao. Aritmetica pura: nao aplica limiar de pontualidade.',
  atraso_chegada_min INT COMMENT 'Minutos entre a chegada programada e a chegada efetiva. Positivo e atraso, negativo e antecipacao.',
  minutos_recuperados INT COMMENT 'Minutos que a etapa recuperou em voo: atraso de partida menos atraso de chegada. Positivo significa que chegou menos atrasada do que saiu.',
  _arquivo_origem STRING COLLATE UTF8_BINARY COMMENT 'Auditoria: nome do arquivo CSV mensal da ANAC de onde a linha veio.',
  _ingerido_em TIMESTAMP COMMENT 'Auditoria: momento em que a linha entrou no bronze.',
  _transformado_em TIMESTAMP COMMENT 'Auditoria: momento em que a silver foi reconstruida a partir do bronze.')
USING delta
COMMENT 'Silver - espelho governado de bronze.vra. Mesmo grao (uma linha por etapa de voo) e MESMA contagem de linhas do bronze: sem filtro, sem agregacao e sem regra de negocio. Traz tipagem, data e hora separadas e as tres metricas de aritmetica pura de atraso. Pontualidade, escopo e exclusoes ficam na gold.'
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

-- Estrutura da tabela vra_quarentena
CREATE MATERIALIZED VIEW `voebem`.`silver`.`vra_quarentena` (
  icao_empresa STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO de tres letras da empresa aerea que operou a etapa. Chave para silver.empresas.',
  numero_voo STRING COLLATE UTF8_BINARY COMMENT 'Numero do voo divulgado pela companhia. Identificador comercial, nao numerico: pode ter zero a esquerda e se repete entre datas.',
  codigo_di STRING COLLATE UTF8_BINARY COMMENT 'Codigo de autorizacao (DI) da etapa: distingue etapa regular, extra, de retorno, charter. Descricao em silver.codigos_operacao (dominio codigo_di).',
  codigo_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Codigo do tipo de linha: N e C domesticas, I e G internacionais. Descricao em silver.codigos_operacao (dominio codigo_tipo_linha).',
  icao_origem STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aerodromo de onde a etapa partiu. Chave para silver.aerodromos - aeroportos estrangeiros nao constam no cadastro da ANAC.',
  icao_destino STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aerodromo onde a etapa pousou. Mesma observacao de cobertura da origem.',
  partida_prevista TIMESTAMP COMMENT 'Horario de partida programado pela companhia, na hora local do aeroporto de origem.',
  partida_prevista_data DATE COMMENT 'Data da partida programada, separada para facilitar analise por dia.',
  partida_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da partida programada (HH:mm), separada para analise por faixa horaria.',
  partida_real TIMESTAMP COMMENT 'Horario em que a aeronave efetivamente saiu. Nulo em voo cancelado, que nao chegou a partir.',
  partida_real_data DATE COMMENT 'Data da partida efetiva.',
  partida_real_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da partida efetiva (HH:mm).',
  chegada_prevista TIMESTAMP COMMENT 'Horario de chegada programado, na hora local do aeroporto de destino.',
  chegada_prevista_data DATE COMMENT 'Data da chegada programada.',
  chegada_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da chegada programada (HH:mm).',
  chegada_real TIMESTAMP COMMENT 'Horario em que a aeronave efetivamente pousou. Nulo em voo cancelado.',
  chegada_real_data DATE COMMENT 'Data da chegada efetiva.',
  chegada_real_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto da chegada efetiva (HH:mm).',
  situacao_voo STRING COLLATE UTF8_BINARY COMMENT 'Situacao informada pela companhia: REALIZADO quando a etapa aconteceu, CANCELADO quando nao.',
  codigo_justificativa STRING COLLATE UTF8_BINARY COMMENT 'Motivo declarado do atraso. Deixou de ser exigido pela ANAC em abril de 2020 com a revogacao da IAC 1504: vem vazio em toda a janela deste projeto.',
  atraso_partida_min INT COMMENT 'Minutos entre a partida programada e a partida efetiva. Positivo e atraso, negativo e antecipacao. Aritmetica pura: nao aplica limiar de pontualidade.',
  atraso_chegada_min INT COMMENT 'Minutos entre a chegada programada e a chegada efetiva. Positivo e atraso, negativo e antecipacao.',
  minutos_recuperados INT COMMENT 'Minutos que a etapa recuperou em voo: atraso de partida menos atraso de chegada. Positivo significa que chegou menos atrasada do que saiu.',
  _arquivo_origem STRING COLLATE UTF8_BINARY COMMENT 'Auditoria: nome do arquivo CSV mensal da ANAC de onde a linha veio.',
  _ingerido_em TIMESTAMP COMMENT 'Auditoria: momento em que a linha entrou no bronze.',
  _transformado_em TIMESTAMP COMMENT 'Auditoria: momento em que a silver foi reconstruida a partir do bronze.',
  origem_no_cadastro BOOLEAN,
  destino_no_cadastro BOOLEAN,
  empresa_no_cadastro BOOLEAN,
  motivos_quarentena STRING COLLATE UTF8_BINARY,
  _quarentenado_em TIMESTAMP)
COMMENT 'Silver quarentena - espelho DIAGNOSTICO dos registros de silver.vra que
 reprovaram em alguma expectation do contrato de dados, com o motivo por registro.
 NAO e filtro: silver.vra permanece com a contagem original. A decisao de excluir
 ou nao cada categoria e de negocio e acontece na gold.'
AS SELECT
  *,
  concat_ws(' | ',
    CASE WHEN partida_prevista IS NULL OR chegada_prevista IS NULL
         THEN 'horarios_previstos_presentes' END,
    CASE WHEN situacao_voo NOT IN ('REALIZADO', 'CANCELADO') OR situacao_voo IS NULL
         THEN 'situacao_voo_conhecida' END,
    CASE WHEN partida_prevista IS NOT NULL AND chegada_prevista IS NOT NULL
              AND chegada_prevista <= partida_prevista
         THEN 'chegada_prevista_depois_da_partida_prevista' END,
    CASE WHEN partida_real IS NOT NULL AND chegada_real IS NOT NULL
              AND chegada_real <= partida_real
         THEN 'chegada_real_depois_da_partida_real' END,
    CASE WHEN atraso_partida_min IS NOT NULL
              AND (atraso_partida_min < -120 OR atraso_partida_min > 1440)
         THEN 'atraso_partida_plausivel' END,
    CASE WHEN atraso_chegada_min IS NOT NULL
              AND (atraso_chegada_min < -120 OR atraso_chegada_min > 1440)
         THEN 'atraso_chegada_plausivel' END,
    CASE WHEN NOT empresa_no_cadastro THEN 'empresa_no_cadastro_anac' END,
    CASE WHEN NOT origem_no_cadastro THEN 'aeroporto_origem_no_cadastro_anac' END,
    CASE WHEN NOT destino_no_cadastro THEN 'aeroporto_destino_no_cadastro_anac' END
  ) AS motivos_quarentena,
  current_timestamp() AS _quarentenado_em
FROM vra_auditado
WHERE NOT (
      partida_prevista IS NOT NULL AND chegada_prevista IS NOT NULL
  AND situacao_voo IN ('REALIZADO', 'CANCELADO')
  AND (partida_prevista IS NULL OR chegada_prevista IS NULL OR chegada_prevista > partida_prevista)
  AND (partida_real IS NULL OR chegada_real IS NULL OR chegada_real > partida_real)
  AND (atraso_partida_min IS NULL OR atraso_partida_min BETWEEN -120 AND 1440)
  AND (atraso_chegada_min IS NULL OR atraso_chegada_min BETWEEN -120 AND 1440)
  AND empresa_no_cadastro
  AND origem_no_cadastro
  AND destino_no_cadastro
)
;

