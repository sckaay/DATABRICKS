-- SCRIPT DE CRIAÇÃO DO SCHEMA GOLD
CREATE SCHEMA IF NOT EXISTS voebem.gold;

-- Estrutura da tabela dim_aeroporto
CREATE TABLE voebem.gold.dim_aeroporto (
  icao_aeroporto STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aeroporto. Chave da dimensao, serve tanto para origem quanto para destino do fato.',
  nome_aeroporto STRING COLLATE UTF8_BINARY COMMENT 'Nome do aeroporto. Traz fallback textual com o codigo quando o aeroporto nao esta no cadastro da ANAC.',
  municipio_aeroporto STRING COLLATE UTF8_BINARY COMMENT 'Municipio onde o aeroporto esta localizado. Vazio para aeroporto estrangeiro.',
  uf_aeroporto STRING COLLATE UTF8_BINARY COMMENT 'Unidade federativa por extenso, como a ANAC publica. Nao e a sigla.',
  pais_aeroporto STRING COLLATE UTF8_BINARY COMMENT 'Brasil ou Exterior, deduzido do prefixo ICAO. Regra de negocio criada na gold.',
  no_cadastro_anac BOOLEAN COMMENT 'Verdadeiro quando o aeroporto existe no cadastro de aerodromos publicos da ANAC. Falso e o esperado para aeroporto estrangeiro, e nao indica erro.',
  _processado_em TIMESTAMP COMMENT 'Auditoria: momento da construcao da dimensao.')
USING delta
COMMENT 'Gold - dimensao de aeroporto, servindo origem e destino do fato. Construida a partir dos codigos presentes no fato e enriquecida pelo cadastro da ANAC, para cobrir 100 por cento do fato inclusive os aeroportos estrangeiros, que a ANAC nao cadastra.'
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

-- Estrutura da tabela fato_voos
CREATE TABLE voebem.gold.fato_voos (
  icao_empresa STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO de tres letras da companhia que operou a etapa. Use nome_companhia para exibir; este codigo serve para filtro exato.',
  nome_companhia STRING COLLATE UTF8_BINARY COMMENT 'Razao social da companhia aerea. Quando o codigo nao existe no cadastro da ANAC, traz COMPANHIA NAO CADASTRADA seguida do codigo, em vez de vazio.',
  cadastro_companhia STRING COLLATE UTF8_BINARY COMMENT 'De qual cadastro da ANAC veio a companhia: nacional ou estrangeira. Nulo quando o codigo nao tem cadastro.',
  numero_voo STRING COLLATE UTF8_BINARY COMMENT 'Numero comercial do voo divulgado pela companhia. Nao e identificador unico: o mesmo numero se repete todos os dias.',
  codigo_di STRING COLLATE UTF8_BINARY COMMENT 'Codigo de autorizacao da etapa (DI) publicado pela ANAC. O codigo 1 aparece no dado e nao consta na tabela oficial de descricoes.',
  descricao_di STRING COLLATE UTF8_BINARY COMMENT 'Tipo da etapa por extenso: regular, extra, de retorno, charter, fretamento. Quando o codigo nao esta catalogado pela ANAC, diz isso explicitamente.',
  codigo_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Codigo do tipo de linha da ANAC: N e C domesticas, I e G internacionais.',
  descricao_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Tipo de linha por extenso, combinando escopo e natureza da operacao: Domestica Mista, Internacional Cargueira, etc.',
  escopo_voo STRING COLLATE UTF8_BINARY COMMENT 'Classificacao de negocio do voo em Domestico ou Internacional, derivada do tipo de linha. E a coluna certa para comparar os dois universos.',
  icao_origem STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aeroporto de partida. Chave para gold.dim_aeroporto.',
  icao_destino STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aeroporto de chegada. Chave para gold.dim_aeroporto.',
  rota STRING COLLATE UTF8_BINARY COMMENT 'Rota no formato ORIGEM - DESTINO usando codigos ICAO.',
  partida_prevista TIMESTAMP COMMENT 'Data e hora que a companhia programou para a partida, na hora local do aeroporto de origem.',
  partida_prevista_data DATE COMMENT 'Data programada da partida. Use para series diarias e para recortar periodo.',
  partida_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto programados da partida, no formato HH:mm, para leitura.',
  hora_partida_prevista INT COMMENT 'Hora cheia programada da partida, de 0 a 23. E a coluna certa para analisar o efeito cascata do atraso ao longo do dia.',
  dia_semana STRING COLLATE UTF8_BINARY COMMENT 'Dia da semana da partida programada, por extenso e em minusculas (domingo a sabado).',
  mes_referencia TIMESTAMP COMMENT 'Primeiro dia do mes da partida programada, para agregacao mensal. E nulo nos voos que nao tem horario previsto informado.',
  partida_real TIMESTAMP COMMENT 'Data e hora em que a aeronave efetivamente partiu. Nulo em voo cancelado.',
  chegada_prevista TIMESTAMP COMMENT 'Data e hora programadas para a chegada, na hora local do aeroporto de destino.',
  chegada_real TIMESTAMP COMMENT 'Data e hora em que a aeronave efetivamente pousou. Nulo em voo cancelado.',
  atraso_partida_min INT COMMENT 'Atraso de partida em minutos: horario real menos programado. Negativo significa que saiu adiantado. Nulo quando o voo foi cancelado, quando nao ha horario programado, ou quando o valor esta fora da faixa plausivel.',
  atraso_chegada_min INT COMMENT 'Atraso de chegada em minutos: horario real menos programado. Negativo significa que pousou adiantado. Mesmas regras de nulo do atraso de partida.',
  minutos_recuperados INT COMMENT 'Minutos que a etapa recuperou no ar: atraso de partida menos atraso de chegada. Positivo significa que chegou MENOS ATRASADA do que saiu, e NAO que chegou no horario - um voo pode recuperar 20 minutos e ainda assim pousar atrasado. Negativo significa que perdeu ainda mais tempo depois de decolar.',
  atraso_fora_de_faixa BOOLEAN COMMENT 'Verdadeiro quando o atraso calculado estava fora da faixa plausivel (menos de -2h ou mais de 24h), sinal de erro de data na origem. A linha continua contando como voo, mas as tres metricas de atraso foram anuladas.',
  partida_pontual BOOLEAN COMMENT 'Verdadeiro quando a partida atrasou 15 minutos ou menos, criterio de pontualidade deste projeto. Falso significa atraso maior que 15 minutos. Nulo significa que NAO DA para avaliar - voo cancelado ou sem horario programado - e nunca deve ser contado como atraso.',
  chegada_pontual BOOLEAN COMMENT 'Verdadeiro quando a chegada atrasou 15 minutos ou menos. Mesma regra de nulo da pontualidade de partida.',
  situacao_voo STRING COLLATE UTF8_BINARY COMMENT 'Situacao informada pela companhia: REALIZADO quando a etapa aconteceu, CANCELADO quando nao aconteceu.',
  voo_cancelado BOOLEAN COMMENT 'Verdadeiro quando a etapa foi cancelada. Voo cancelado NAO entra em nenhuma media de atraso, porque nao tem horario real; use esta coluna para taxa de cancelamento.',
  voo_realizado BOOLEAN COMMENT 'Verdadeiro quando a etapa foi realizada. Use como denominador de metricas operacionais.',
  _processado_em TIMESTAMP COMMENT 'Auditoria: momento em que esta linha foi construida na camada gold.')
USING delta
COMMENT 'Gold - fato de voos no grao de uma linha por etapa, com companhia e codigos de operacao como dimensoes degeneradas. E aqui que nascem as regras de negocio: pontualidade a 15 minutos, escopo domestico/internacional e as decisoes sobre a quarentena. Contagem = silver.vra menos 41 duplicatas exatas.'
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

-- Estrutura da tabela obt_voos
CREATE TABLE voebem.gold.obt_voos (
  icao_empresa STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO de tres letras da companhia que operou a etapa. Use nome_companhia para exibir; este codigo serve para filtro exato.',
  nome_companhia STRING COLLATE UTF8_BINARY COMMENT 'Razao social da companhia aerea. Quando o codigo nao existe no cadastro da ANAC, traz COMPANHIA NAO CADASTRADA seguida do codigo, em vez de vazio.',
  numero_voo STRING COLLATE UTF8_BINARY COMMENT 'Numero comercial do voo divulgado pela companhia. Nao e identificador unico: o mesmo numero se repete todos os dias.',
  codigo_di STRING COLLATE UTF8_BINARY COMMENT 'Codigo de autorizacao da etapa (DI) publicado pela ANAC. O codigo 1 aparece no dado e nao consta na tabela oficial de descricoes.',
  descricao_di STRING COLLATE UTF8_BINARY COMMENT 'Tipo da etapa por extenso: regular, extra, de retorno, charter, fretamento. Quando o codigo nao esta catalogado pela ANAC, diz isso explicitamente.',
  codigo_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Codigo do tipo de linha da ANAC: N e C domesticas, I e G internacionais.',
  descricao_tipo_linha STRING COLLATE UTF8_BINARY COMMENT 'Tipo de linha por extenso, combinando escopo e natureza da operacao: Domestica Mista, Internacional Cargueira, etc.',
  escopo_voo STRING COLLATE UTF8_BINARY COMMENT 'Classificacao de negocio do voo em Domestico ou Internacional, derivada do tipo de linha. E a coluna certa para comparar os dois universos.',
  icao_origem STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aeroporto de partida. Use nome_aeroporto_origem para exibir.',
  nome_aeroporto_origem STRING COLLATE UTF8_BINARY COMMENT 'Nome do aeroporto de partida. Aeroporto estrangeiro nao consta no cadastro da ANAC e aparece como AEROPORTO FORA DO CADASTRO ANAC seguido do codigo.',
  municipio_origem STRING COLLATE UTF8_BINARY COMMENT 'Municipio do aeroporto de partida. Vazio para aeroporto estrangeiro, que nao esta no cadastro brasileiro.',
  uf_origem STRING COLLATE UTF8_BINARY COMMENT 'Unidade federativa do aeroporto de partida, escrita POR EXTENSO (Sao Paulo, Ceara), como a ANAC publica. Nao e a sigla.',
  pais_origem STRING COLLATE UTF8_BINARY COMMENT 'Brasil ou Exterior, deduzido do prefixo do codigo ICAO. Serve para separar operacao domestica de internacional pelo lado do aeroporto.',
  icao_destino STRING COLLATE UTF8_BINARY COMMENT 'Codigo ICAO do aeroporto de chegada. Use nome_aeroporto_destino para exibir.',
  nome_aeroporto_destino STRING COLLATE UTF8_BINARY COMMENT 'Nome do aeroporto de chegada. Mesma regra de fallback do aeroporto de origem.',
  municipio_destino STRING COLLATE UTF8_BINARY COMMENT 'Municipio do aeroporto de chegada. Vazio para aeroporto estrangeiro.',
  uf_destino STRING COLLATE UTF8_BINARY COMMENT 'Unidade federativa do aeroporto de chegada, por extenso.',
  pais_destino STRING COLLATE UTF8_BINARY COMMENT 'Brasil ou Exterior para o aeroporto de chegada.',
  rota_icao STRING COLLATE UTF8_BINARY COMMENT 'Rota no formato ORIGEM - DESTINO usando codigos ICAO. E a chave estavel para agrupar por rota.',
  rota_municipios STRING COLLATE UTF8_BINARY COMMENT 'Rota no formato municipio de origem - municipio de destino, para leitura humana. Aeroporto estrangeiro aparece pelo codigo ICAO, porque nao tem municipio no cadastro.',
  partida_prevista TIMESTAMP COMMENT 'Data e hora que a companhia programou para a partida, na hora local do aeroporto de origem.',
  partida_prevista_data DATE COMMENT 'Data programada da partida. Use para series diarias e para recortar periodo.',
  partida_prevista_hora STRING COLLATE UTF8_BINARY COMMENT 'Hora e minuto programados da partida, no formato HH:mm, para leitura.',
  hora_partida_prevista INT COMMENT 'Hora cheia programada da partida, de 0 a 23. E a coluna certa para analisar o efeito cascata do atraso ao longo do dia.',
  dia_semana STRING COLLATE UTF8_BINARY COMMENT 'Dia da semana da partida programada, por extenso e em minusculas (domingo a sabado).',
  mes_referencia TIMESTAMP COMMENT 'Primeiro dia do mes da partida programada, para agregacao mensal. E nulo nos voos que nao tem horario previsto informado.',
  partida_real TIMESTAMP COMMENT 'Data e hora em que a aeronave efetivamente partiu. Nulo em voo cancelado.',
  chegada_prevista TIMESTAMP COMMENT 'Data e hora programadas para a chegada, na hora local do aeroporto de destino.',
  chegada_real TIMESTAMP COMMENT 'Data e hora em que a aeronave efetivamente pousou. Nulo em voo cancelado.',
  atraso_partida_min INT COMMENT 'Atraso de partida em minutos: horario real menos programado. Negativo significa que saiu adiantado. Nulo quando o voo foi cancelado, quando nao ha horario programado, ou quando o valor esta fora da faixa plausivel.',
  atraso_chegada_min INT COMMENT 'Atraso de chegada em minutos: horario real menos programado. Negativo significa que pousou adiantado. Mesmas regras de nulo do atraso de partida.',
  minutos_recuperados INT COMMENT 'Minutos que a etapa recuperou no ar: atraso de partida menos atraso de chegada. Positivo significa que chegou MENOS ATRASADA do que saiu, e NAO que chegou no horario - um voo pode recuperar 20 minutos e ainda assim pousar atrasado. Negativo significa que perdeu ainda mais tempo depois de decolar.',
  atraso_fora_de_faixa BOOLEAN COMMENT 'Verdadeiro quando o atraso calculado estava fora da faixa plausivel (menos de -2h ou mais de 24h), sinal de erro de data na origem. A linha continua contando como voo, mas as tres metricas de atraso foram anuladas.',
  partida_pontual BOOLEAN COMMENT 'Verdadeiro quando a partida atrasou 15 minutos ou menos, criterio de pontualidade deste projeto. Falso significa atraso maior que 15 minutos. Nulo significa que NAO DA para avaliar - voo cancelado ou sem horario programado - e nunca deve ser contado como atraso.',
  chegada_pontual BOOLEAN COMMENT 'Verdadeiro quando a chegada atrasou 15 minutos ou menos. Mesma regra de nulo da pontualidade de partida.',
  situacao_voo STRING COLLATE UTF8_BINARY COMMENT 'Situacao informada pela companhia: REALIZADO quando a etapa aconteceu, CANCELADO quando nao aconteceu.',
  voo_realizado BOOLEAN COMMENT 'Verdadeiro quando a etapa foi realizada. Use como denominador de metricas operacionais.',
  voo_cancelado BOOLEAN COMMENT 'Verdadeiro quando a etapa foi cancelada. Voo cancelado NAO entra em nenhuma media de atraso, porque nao tem horario real; use esta coluna para taxa de cancelamento.',
  _processado_em TIMESTAMP COMMENT 'Auditoria: momento em que esta linha foi construida na camada gold.')
USING delta
COMMENT 'Gold - One Big Table de voos da ANAC, desnormalizada e desenhada para consumo por agente de IA. Uma linha por etapa de voo, com nomes ja resolvidos e metricas prontas: responde as perguntas de negocio do projeto sem nenhum JOIN. Criterio de pontualidade: 15 minutos. Voo cancelado nao tem metrica de atraso.'
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

