-- -------------------------------------------------------------------
-- Flag observations to use for current round of range modeling
-- -------------------------------------------------------------------

SET search_path TO analytical_db;

UPDATE range_model_data_raw
SET is_range_model_ob_202209=1
WHERE taxonomic_status='Accepted'
AND is_introduced=0
;

DROP INDEX IF EXISTS range_model_data_raw_is_range_model_ob_202209_idx;
CREATE INDEX range_model_data_raw_is_range_model_ob_202209_idx ON range_model_data_raw(is_range_model_ob_202209);

DROP TABLE IF EXISTS temp_range_model_species;
CREATE TABLE temp_range_model_species AS
SELECT DISTINCT scrubbed_species_binomial 
FROM range_model_data_raw
WHERE is_range_model_ob_202209=1
ORDER BY scrubbed_species_binomial
;
ALTER TABLE temp_range_model_species
ADD CONSTRAINT temp_range_model_species_pk PRIMARY KEY (scrubbed_species_binomial)
;

UPDATE range_model_data_metadata a
SET is_range_model_species_202209=1
FROM temp_range_model_species b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;

DROP TABLE temp_range_model_species;

DROP INDEX IF EXISTS range_model_data_metadata_is_range_model_species_202209_idx;
CREATE INDEX range_model_data_metadata_is_range_model_species_202209_idx ON range_model_data_metadata(is_range_model_species_202209);
