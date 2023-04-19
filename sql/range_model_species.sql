-- -------------------------------------------------------------------
-- Extract range model species attribute table
-- -------------------------------------------------------------------

SET search_path TO :SCH_RMD;

--
-- Extract just species and taxonomic status from RMD table
-- Ensures these two field create unique key
--

DROP TABLE IF EXISTS :TBL_RMS;
CREATE TABLE :TBL_RMS AS
SELECT DISTINCT scrubbed_species_binomial, species_nospace, taxonomic_status
FROM :TBL_RMD
--WHERE delete=0
ORDER BY scrubbed_species_binomial
;
\set TBL_RMS_SSB_IDX :TBL_RMS'_scrubbed_species_binomial_idx'
CREATE INDEX :TBL_RMS_SSB_IDX ON :TBL_RMS(scrubbed_species_binomial);

--
-- Extract higher_plant_group and is_vasc from RMD table
--

DROP TABLE IF EXISTS species_attributes_temp;
CREATE TABLE species_attributes_temp AS
SELECT DISTINCT scrubbed_species_binomial, higher_plant_group, is_vasc
FROM :TBL_RMD
--WHERE delete=0
ORDER BY scrubbed_species_binomial
;
CREATE INDEX species_attributes_temp_scrubbed_species_binomial_idx ON species_attributes_temp(scrubbed_species_binomial);

ALTER TABLE :TBL_RMS
ADD COLUMN higher_plant_group text,
ADD COLUMN is_vasc integer default 1
;

UPDATE :TBL_RMS a
SET higher_plant_group=b.higher_plant_group,
is_vasc=b.is_vasc
FROM species_attributes_temp b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;

-- Tidy up
DROP TABLE species_attributes_temp;

--
-- Extract family and growth from from growth form table in analytical DB
--

ALTER TABLE :TBL_RMS
ADD COLUMN family text,
ADD COLUMN growth_form text
;

UPDATE :TBL_RMS a
SET 
family=b.family,
growth_form=b.gf
FROM :"SCH"."species_growth_forms" b
WHERE a.scrubbed_species_binomial=b.species
;

-- 
-- Save after counts to table range_model_data_stats_${rundate}
--

INSERT INTO :TBL_RMDS (
period,
obs,
species_table_rows,
species
)
SELECT 
'After'::text,
(SELECT COUNT(*) FROM :TBL_RMD)::integer,
(SELECT COUNT(*) FROM :TBL_RMS)::integer,
(SELECT COUNT(DISTINCT scrubbed_species_binomial)::integer FROM :TBL_RMS)::integer
;

-- Add some derived stats
INSERT INTO :TBL_RMDS (
period,
obs,
species_table_rows,
species
)
SELECT
'Diff'::text,
(SELECT obs FROM :TBL_RMDS WHERE period='Before')::integer-
(SELECT obs FROM :TBL_RMDS WHERE period='After')::integer,
(SELECT species_table_rows FROM :TBL_RMDS WHERE period='Before')::integer-
(SELECT species_table_rows FROM :TBL_RMDS WHERE period='After')::integer,
(SELECT species FROM :TBL_RMDS WHERE period='Before')::integer-
(SELECT species FROM :TBL_RMDS WHERE period='After')::integer
;

