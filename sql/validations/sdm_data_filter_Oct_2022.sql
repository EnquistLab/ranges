-- --------------------------------------------------------------
-- Range model data filter for October 2022 run
-- --------------------------------------------------------------

/*
Modifications to previous filter:

Lower time cutoff: 1950
Upper time cutoff: none
Introduced observations: exclude al
Taxonomic status: include all (Ranges models of species with unresolved/ambiguous names can be excluded later, as needed, from specific analyses)
Human observations: exclude
*/

-- Final where clause:

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
AND ( EXTRACT(YEAR FROM event_date)>=1950 ) 

/*
Note especially:
1. Omission of "OR event_date IS NULL". Previous version was:
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL ) 
2. Inclusion of "OR is_introduced IS NULL"
*/

-- Queries to test the effects of 1 & 2 above 

DROP TABLE IF EXISTS sdm_data_test_raw_full;
CREATE TABLE sdm_data_tessdm_data_test_raw_fullt_raw AS
SELECT taxonobservation_id, observation_type, datasource, dataset,
scrubbed_family, scrubbed_species_binomial,
country, is_introduced, event_date, event_date_verbatim, 
date_collected_verbatim
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
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL ) 
;

DROP TABLE IF EXISTS sdm_data_test;
CREATE TABLE sdm_data_test AS
SELECT test, rows FROM (
SELECT 'total_obs'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw
UNION
SELECT 'is_introduced_null'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw
WHERE is_introduced IS NULL
UNION
SELECT 'event_date_null'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw
WHERE event_date IS NULL
) a
;
ALTER TABLE sdm_data_test
ADD COLUMN perc_obs DECIMAL(4,1)
;
UPDATE sdm_data_test
SET perc_obs=CAST(
rows::numeric/
(SELECT rows FROM sdm_data_test WHERE test='total_obs')::numeric
*100::numeric AS DECIMAL(4,1)
) 
;


-- species
DROP TABLE IF EXISTS sdm_data_test_spp;
CREATE TABLE sdm_data_test_spp AS
SELECT test, species FROM (
SELECT 'total_spp'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw
UNION
SELECT 'is_introduced_null'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw
WHERE is_introduced IS NULL
UNION
SELECT 'event_date_null'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw
WHERE event_date IS NULL
) a
;
ALTER TABLE sdm_data_test_spp
ADD COLUMN perc_spp DECIMAL(4,1)
;
UPDATE sdm_data_test_spp
SET perc_spp=CAST(
species::numeric/
(SELECT species FROM sdm_data_test_spp WHERE test='total_spp')::numeric
*100::numeric AS DECIMAL(4,1)
) 
;

DROP TABLE IF EXISTS sdm_data_test_data_null_country;
CREATE TABLE sdm_data_test_data_null_country AS
SELECT country, COUNT(*) AS obs
FROM sdm_data_test_raw
WHERE is_introduced IS NULL
GROUP BY country
ORDER BY country
;

-- Select queries

SELECT * FROM sdm_data_test;

SELECT * FROM sdm_data_test_data_null_country;

select * from sdm_data_test_raw where event_date is null limit 12;

SELECT observation_type, datasource, dataset, scrubbed_family, scrubbed_species_binomial,
country, is_introduced, event_date_verbatim, date_collected_verbatim
FROM sdm_data_test_raw 
WHERE event_date IS NULL
LIMIT 12;


SELECT datasource, dataset, COUNT(*)
FROM sdm_data_test_raw 
WHERE event_date IS NULL AND observation_type='plot'
GROUP BY datasource, dataset
;

-- Count numbers and proportions of rows by observation_type
SELECT observation_type, COUNT(*) AS rows,
(COUNT(*)::numeric / 1000000 * 100)::decimal(4,1) AS prop_rows
FROM sdm_data_test_raw
WHERE event_date IS NULL
GROUP BY observation_type
;

--
-- Get full set of records and index the key cols
--

DROP TABLE IF EXISTS sdm_data_test_raw_full;
-- CREATE TABLE sdm_data_tessdm_data_test_raw_fullt_raw AS  -- orig bad line
CREATE TABLE sdm_data_test_raw_full AS
SELECT taxonobservation_id, observation_type, datasource, dataset,
scrubbed_family, scrubbed_species_binomial,
country, is_introduced, event_date, event_date_verbatim, 
date_collected_verbatim
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
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL ) 
;

ALTER TABLE sdm_data_test_raw_full
ADD CONSTRAINT sdm_data_test_raw_full_pk PRIMARY KEY (taxonobservation_id)
;

CREATE INDEX sdm_data_test_raw_full_event_date_null_idx ON
sdm_data_test_raw_full (event_date)
WHERE event_date IS NULL
;

CREATE INDEX sdm_data_test_raw_full_is_introduced_null_idx ON
sdm_data_test_raw_full (is_introduced)
WHERE is_introduced IS NULL
;

-- obs
DROP TABLE IF EXISTS sdm_data_test_full;
CREATE TABLE sdm_data_test_full AS
SELECT test, rows FROM (
SELECT 'total_obs'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw_full
UNION
SELECT 'is_introduced_null'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw_full
WHERE is_introduced IS NULL
UNION
SELECT 'event_date_null'::text AS test, COUNT(*) AS rows
FROM sdm_data_test_raw_full
WHERE event_date IS NULL
) a
;
ALTER TABLE sdm_data_test_full
ADD COLUMN perc_obs DECIMAL(4,1)
;
UPDATE sdm_data_test_full
SET perc_obs=CAST(
rows::numeric/
(SELECT rows FROM sdm_data_test_full WHERE test='total_obs')::numeric
*100::numeric AS DECIMAL(4,1)
) 
;

-- species
DROP TABLE IF EXISTS sdm_data_test_raw_full_spp;
CREATE TABLE sdm_data_test_raw_full_spp AS
SELECT test, species FROM (
SELECT 'total_spp'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw_full
UNION
SELECT 'is_introduced_null'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw_full
WHERE is_introduced IS NULL
UNION
SELECT 'event_date_null'::text AS test, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM sdm_data_test_raw_full
WHERE event_date IS NULL
) a
;
ALTER TABLE sdm_data_test_raw_full_spp
ADD COLUMN perc_spp DECIMAL(4,1)
;
UPDATE sdm_data_test_raw_full_spp
SET perc_spp=CAST(
species::numeric/
(SELECT species FROM sdm_data_test_raw_full_spp WHERE test='total_spp')::numeric
*100::numeric AS DECIMAL(4,1)
) 
;

DROP TABLE IF EXISTS sdm_data_test_raw_full_null_country;
CREATE TABLE sdm_data_test_raw_full_null_country AS
SELECT country, COUNT(*) AS obs
FROM sdm_data_test_raw_full
WHERE is_introduced IS NULL
GROUP BY country
ORDER BY country
;







