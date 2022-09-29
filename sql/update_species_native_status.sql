-- ---------------------------------------------------------
-- Populate native_status and is_introduced in table
-- range_model_data_raw by joining to vfoi on species
-- ---------------------------------------------------------

SET search_path TO analytical_db;

-- UPDATE range_model_data_raw a
-- SET native_status=b.native_status,
-- is_introduced=b.is_introduced
-- FROM view_full_occurrence_individual b
-- WHERE a.scrubbed_species_binomial=:'SPECIES'
-- AND b.scrubbed_species_binomial=:'SPECIES'
-- AND a.taxonobservation_id=b.taxonobservation_id
-- ;

SET work_mem = '16GB';

UPDATE range_model_data_raw a
SET native_status=b.native_status,
is_introduced=b.is_introduced
FROM view_full_occurrence_individual b
WHERE b.scrubbed_species_binomial=:'SPECIES'
AND a.taxonobservation_id=b.taxonobservation_id
;

RESET work_mem;

