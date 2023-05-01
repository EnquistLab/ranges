-- -------------------------------------------------------------------
-- Extract raw range model data table
-- -------------------------------------------------------------------

SET search_path TO :SCH_RMD;

--
-- Extract the raw data
-- 

-- See params file for SQL_WHERE and LIMITCLAUSE 
DROP TABLE IF EXISTS :TBL_RMD;
CREATE TABLE :TBL_RMD AS
:SQL_SELECT
FROM :"SCH"."view_full_occurrence_individual"
:SQL_WHERE
:SQL_LIMIT
;

--
-- Prepare additional fields
--

ALTER TABLE :TBL_RMD
ADD COLUMN species_nospace text,
ADD COLUMN is_vasc INTEGER DEFAULT 0,
ADD COLUMN event_year INTEGER DEFAULT NULL,
ADD COLUMN decade INTEGER DEFAULT NULL
;

UPDATE :TBL_RMD
SET species_nospace=REPLACE(scrubbed_species_binomial, ' ', '_')
;

UPDATE :TBL_RMD
SET event_year=date_part('year', event_date)
WHERE event_date IS NOT NULL
;
UPDATE :TBL_RMD
SET decade=concat(left((event_year::text), 3), '0')::int
WHERE event_year IS NOT NULL
;

UPDATE :TBL_RMD
SET is_vasc=1
WHERE higher_plant_group IN ('ferns and allies','flowering plants','gymnosperms (conifers)', 'gymnosperms (non-conifer)')
;

UPDATE :TBL_RMD
SET taxonomic_status='Unresolved'
WHERE taxonomic_status='No opinion'
;

--
-- Add indexes
--

\set TBL_RMD_SSB_IDX :TBL_RMD'_scrubbed_species_binomial_idx'
DROP INDEX IF EXISTS :"TBL_RMD_SSB_IDX";
CREATE INDEX :"TBL_RMD_SSB_IDX" ON :TBL_RMD (scrubbed_species_binomial);

\set TBL_RMD_SNS_IDX :TBL_RMD'_species_nospace_idx'
DROP INDEX IF EXISTS :"TBL_RMD_SNS_IDX";
CREATE INDEX :"TBL_RMD_SNS_IDX" ON :TBL_RMD (species_nospace);




