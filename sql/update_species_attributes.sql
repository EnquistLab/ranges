-- -------------------------------------------------------------------
-- Add species-level attributes to range_model_data_raw & is_vasc
-- attribute to species attribute table
-- -------------------------------------------------------------------

SET search_path TO analytical_db;

--
-- Add species attributes to range_model_data_raw
--

UPDATE range_model_data_raw a
SET 
taxonomic_status=b.taxonomic_status,
higher_plant_group=b.higher_plant_group
FROM range_model_data_metadata b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;

DROP INDEX IF EXISTS range_model_data_raw_higher_plant_group_idx;
CREATE INDEX range_model_data_raw_higher_plant_group_idx ON range_model_data_raw(higher_plant_group);

UPDATE range_model_data_raw
SET is_vasc=1
WHERE higher_plant_group IN (
'ferns and allies',
'gymnosperms (non-conifer)',
'gymnosperms (conifers)',
'flowering plants'
);

DROP INDEX IF EXISTS range_model_data_raw_is_vasc_idx;
CREATE INDEX range_model_data_raw_is_vasc_idx ON range_model_data_raw(is_vasc);

--
-- Populate column is_vasc in range_model_data_metadata
--

UPDATE range_model_data_metadata
SET species_nospace=REPLACE(scrubbed_species_binomial,' ','_')
;
 
UPDATE range_model_data_metadata
SET is_vasc=1
WHERE higher_plant_group IN (
'ferns and allies',
'gymnosperms (non-conifer)',
'gymnosperms (conifers)',
'flowering plants'
);

DROP INDEX IF EXISTS range_model_data_metadata_is_vasc_idx;
CREATE INDEX range_model_data_metadata_is_vasc_idx ON range_model_data_metadata(is_vasc);



