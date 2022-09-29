-- -------------------------------------------------------------------
-- Add species-level attribute columns to range_model_data_raw
-- and indexes 
-- -------------------------------------------------------------------

SET search_path TO analytical_db;

--
-- Alter table range_model_data_raw
--

ALTER TABLE range_model_data_raw
DROP COLUMN IF EXISTS taxonomic_status,
DROP COLUMN IF EXISTS higher_plant_group,
DROP COLUMN IF EXISTS is_vasc,
DROP COLUMN IF EXISTS native_status,
DROP COLUMN IF EXISTS is_introduced,
DROP COLUMN IF EXISTS is_range_model_ob_202209
;
ALTER TABLE range_model_data_raw
ADD COLUMN taxonomic_status text,
ADD COLUMN higher_plant_group text,
ADD COLUMN is_vasc INTEGER DEFAULT 0,
ADD COLUMN native_status text,
ADD COLUMN is_introduced INTEGER DEFAULT 1,
ADD COLUMN is_range_model_ob_202209 INTEGER DEFAULT 0
;

DROP INDEX IF EXISTS range_model_data_raw_scrubbed_species_binomial_idx;
CREATE INDEX range_model_data_raw_scrubbed_species_binomial_idx ON range_model_data_raw(scrubbed_species_binomial);

ALTER TABLE range_model_data_raw DROP CONSTRAINT IF EXISTS range_model_data_raw_pk;
ALTER TABLE range_model_data_raw
ADD CONSTRAINT range_model_data_raw_pk PRIMARY KEY (taxonobservation_id)
;

--
-- Alter table range_model_data_metadata
--

ALTER TABLE range_model_data_metadata
DROP COLUMN IF EXISTS is_vasc,
DROP COLUMN IF EXISTS species_nospace,
DROP COLUMN IF EXISTS is_range_model_species_202209
;
ALTER TABLE range_model_data_metadata
ADD COLUMN is_vasc INTEGER DEFAULT 0,
ADD COLUMN species_nospace text,
ADD COLUMN is_range_model_species_202209  INTEGER DEFAULT 0
;

DROP INDEX IF EXISTS range_model_data_metadata_higher_plant_group_idx;
CREATE INDEX range_model_data_metadata_higher_plant_group_idx ON range_model_data_metadata(higher_plant_group);



