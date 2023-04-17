-- -------------------------------------------------------------------
-- Extract raw range model data table
-- -------------------------------------------------------------------

SET search_path TO :SCH;

DROP TABLE IF EXISTS :TBL_RMD;
CREATE TABLE :TBL_RMD AS
SELECT taxonobservation_id, 
scrubbed_species_binomial, latitude, longitude, 
scrubbed_taxonomic_status AS taxonomic_status, higher_plant_group, 
country, native_status, is_introduced, 
observation_type, event_date
FROM view_full_occurrence_individual
WHERE scrubbed_species_binomial IS NOT NULL 
AND higher_plant_group IN ('bryophytes', 'ferns and allies','flowering plants','gymnosperms (conifers)', 'gymnosperms (non-conifer)') 
AND is_invalid_latlong=0 
AND is_geovalid = 1 
AND (georef_protocol is NULL OR georef_protocol<>'county_centroid') 
AND (is_centroid IS NULL OR is_centroid=0) 
AND is_location_cultivated IS NULL 
AND (is_cultivated_observation = 0 OR is_cultivated_observation IS NULL) 
AND (is_introduced=0 OR is_introduced IS NULL) 
AND observation_type IN ('plot','specimen','literature','checklist') 
-- AND ( EXTRACT(YEAR FROM event_date)>=1950 OR (event_date IS NULL AND observation_type<>'specimen') )
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL )
:LIMITCLAUSE
;

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

DROP INDEX IF EXISTS :"TBL_RMD_SSB_IDX";
CREATE INDEX :"TBL_RMD_SSB_IDX" ON :TBL_RMD (scrubbed_species_binomial);

DROP INDEX IF EXISTS :"TBL_RMD_SNS_IDX";
CREATE INDEX :"TBL_RMD_SNS_IDX" ON :TBL_RMD (species_nospace);



