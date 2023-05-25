-- --------------------------------------------------------------------
-- Check attributes of species *not* modelled
-- --------------------------------------------------------------------

/* 
>100,000 species are completely removed from the range model data by
filtering out is_introduced=1. This means that these species do not 
have a single native observation. I suspect these species are 
absent from all NSR checklists, and are therefore being assigned 
native_status='A' (Absent) rather than native_status='I' (Introduced).
For the BIEN DB, we treat native_status='A' as is_introduced=0.

If so, an additional question is, are these species mostly "Unresolved", 
or do the group also contain accepted species?

These queries test the above hypothesis
*/

\set SCH_ADB analytical_db
\set SCH_RMD range_data
\set SQL_LIMIT 'LIMIT 10000'
\set SQL_LIMIT ''
\set TBL_SDM_SPP range_model_species_20230418

\c vegbien
set search_path to :SCH_RMD;

-- Species + taxonomic_status + native_status
DROP TABLE IF EXISTS bien_species;
CREATE TABLE bien_species AS
SELECT scrubbed_species_binomial, 
	string_agg(DISTINCT scrubbed_taxonomic_status, ',' 
	ORDER BY scrubbed_taxonomic_status) AS taxonomic_status,
	string_agg(DISTINCT native_status, ',' 
	ORDER BY native_status) AS native_status,
	COUNT(*) AS obs
	FROM (
	SELECT scrubbed_species_binomial, scrubbed_taxonomic_status, native_status
	FROM :"SCH_ADB".view_full_occurrence_individual
	-- START BIEN range model data WHERE clause, minus filter on "is_introduced"
	WHERE scrubbed_species_binomial IS NOT NULL 
	AND higher_plant_group IN ('bryophytes', 'ferns and allies','flowering plants','gymnosperms (conifers)', 'gymnosperms (non-conifer)') 
	AND is_invalid_latlong=0 
	AND is_geovalid = 1 
	AND (georef_protocol is NULL OR georef_protocol<>'county_centroid') 
	AND (is_centroid IS NULL OR is_centroid=0) 
	AND is_location_cultivated IS NULL 
	AND (is_cultivated_observation = 0 OR is_cultivated_observation IS NULL) 
	AND observation_type IN ('plot','specimen','literature','checklist') 
	AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL )
	-- END BIEN range model data WHERE clause
	:SQL_LIMIT
) a
WHERE scrubbed_species_binomial IS NOT NULL
GROUP BY scrubbed_species_binomial
ORDER BY scrubbed_species_binomial
;

CREATE INDEX bien_species_scrubbed_species_binomial_idx ON bien_species (scrubbed_species_binomial);
CREATE INDEX bien_species_taxonomic_status_idx ON bien_species (taxonomic_status);
CREATE INDEX bien_species_native_status_idx ON bien_species (native_status);

-- Flag modeled species
ALTER TABLE bien_species
ADD COLUMN is_sdm_species smallint DEFAULT 0
;

\set SDM_SPP_SSB_IDX :TBL_SDM_SPP'_scrubbed_species_binomial_idx'
DROP INDEX IF EXISTS :SDM_SPP_SSB_IDX;
CREATE INDEX :SDM_SPP_SSB_IDX ON :TBL_SDM_SPP (scrubbed_species_binomial);

UPDATE bien_species a
SET is_sdm_species=1 
FROM :TBL_SDM_SPP b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;

-- Compare native status of modeled vs not modeled
DROP TABLE IF EXISTS spp_not_modeled_native_status;
CREATE TABLE spp_not_modeled_native_status AS
SELECT is_sdm_species, native_status, sum(obs) AS obs, count(*) AS species
FROM bien_species
GROUP BY is_sdm_species, native_status
ORDER BY is_sdm_species, native_status
;
SELECT * FROM spp_not_modeled_native_status;

-- Check taxonomic status of species not modeled
DROP TABLE IF EXISTS spp_not_modeled_taxonomic_status;
CREATE TABLE spp_not_modeled_taxonomic_status AS
SELECT taxonomic_status, sum(obs) AS obs, count(*) AS species
FROM bien_species
WHERE is_sdm_species=0
GROUP BY taxonomic_status
ORDER BY taxonomic_status
;
SELECT * FROM spp_not_modeled_taxonomic_status;

--
-- Flag species in at least one NSR checklist
--

/* Not so simple. We need to export species list from NSR first. 

In shell: `mysql -u $USER -p`

In MySQL:

```
SELECT 'species'
UNION ALL
SELECT DISTINCT taxon AS species
FROM distribution
WHERE taxon_rank='species'
ORDER BY species
INTO OUTFILE '/tmp/nsr_species.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
;
```

In the shell, change permissions of file so you can import it to Postgres:

```
cd /tmp
sudo chown $USER nsr_species.csv
sudo chgrp $USER nsr_species.csv
```

Log out of MySQL. Continue in Postgres:
*/

DROP TABLE IF EXISTS nsr_species;
CREATE TABLE nsr_species (
species text,
PRIMARY KEY (species)
);

-- Import the file
-- Closing ';' not needed as this is a meta-command, not an SQL statement
\copy nsr_species FROM '/tmp/nsr_species.csv' DELIMITER ',' CSV HEADER

ALTER TABLE bien_species
ADD COLUMN is_in_nsr smallint DEFAULT 0
;

UPDATE bien_species a
SET is_in_nsr=1 
FROM nsr_species b
WHERE a.scrubbed_species_binomial=b.species
;

-- Check taxonomic status of species not modeled
SELECT is_in_nsr, native_status, sum(obs) AS obs, count(*) AS species
FROM bien_species
WHERE is_sdm_species=0
GROUP BY is_in_nsr, native_status
ORDER BY is_in_nsr, native_status
;

--
-- List countries of observation which do not appear in any NSR checklist
--

/* This is easy: all will have native_status='UNK" (unknown) */
DROP TABLE IF EXISTS country_not_in_nsr;
CREATE TABLE country_not_in_nsr AS
SELECT country, COUNT(*) AS obs, COUNT(DISTINCT scrubbed_species_binomial) AS species
FROM (
SELECT country, scrubbed_species_binomial, native_status
FROM :"SCH_ADB".view_full_occurrence_individual
:SQL_LIMIT
) a
WHERE country IS NOT NULL AND native_status='UNK'
GROUP BY country
ORDER BY country
:SQL_LIMIT
;
SELECT * FROM country_not_in_nsr ORDER BY country;

--
-- Export all results as CSV files
--

\copy spp_not_modeled_native_status to /home/boyle/bien/ranges/data/spp_not_modeled_native_status.csv with csv header

\copy spp_not_modeled_taxonomic_status to /home/boyle/bien/ranges/data/spp_not_modeled_taxonomic_status.csv with csv header

\copy country_not_in_nsr to /home/boyle/bien/ranges/data/country_not_in_nsr.csv with csv header

