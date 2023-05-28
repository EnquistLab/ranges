-- ----------------------------------------------------------------
-- Create table "bien_spp_native_status" consisting of all BIEN 
-- species accompanied by a list of all native_status values 
-- assigned by the NSR
-- 
-- This table is used to identify species are not present in any 
-- NSR checklist. Such species are omitted from the first run of 
-- species range model data because they have no observations 
-- where is_introduced=1. These species can still be modeled, 
-- but the models should be flagged as less certain as is is not 
-- known if they are based on 100% native observations
-- ----------------------------------------------------------------

set search_path to :SCH_RMD;

-- Species + taxonomic_status + native_status
-- NOTE: use only SQL_WHERE_MAIN, do NOT include SQL_WHERE_INTRODUCED!
DROP TABLE IF EXISTS bien_species_native_status;
CREATE TABLE bien_species_native_status AS
SELECT scrubbed_species_binomial, 
	string_agg(DISTINCT is_introduced::text, ',' 
	ORDER BY is_introduced::text) AS is_introduced,
	string_agg(DISTINCT native_status, ',' 
	ORDER BY native_status) AS native_status,
	COUNT(*) AS obs
	FROM (
	SELECT scrubbed_species_binomial, native_status, is_introduced
	FROM :"SCH_ADB".view_full_occurrence_individual
	-- BIEN range model data WHERE clause, minus filter on "is_introduced":
	:SQL_WHERE_MAIN
	:SQL_LIMIT
) a
WHERE scrubbed_species_binomial IS NOT NULL
GROUP BY scrubbed_species_binomial
ORDER BY scrubbed_species_binomial
;
CREATE INDEX bien_species_native_status_scrubbed_species_binomial_idx 
	ON bien_species_native_status (scrubbed_species_binomial);
CREATE INDEX bien_species_native_status_native_status_idx 
	ON bien_species_native_status (native_status);

-- Add column to track species already modeled
ALTER TABLE bien_species_native_status
ADD COLUMN is_sdm_species smallint DEFAULT 0
;

-- Index species name column in the main modeled species table
\set tbl_spp_run1_ssb_idx :TBL_SPP_RUN1 _scrubbed_species_binomial_idx
DROP INDEX IF EXISTS :tbl_spp_run1_ssb_idx;
CREATE INDEX :tbl_spp_run1_ssb_idx 
	ON :TBL_SPP_RUN1 (scrubbed_species_binomial);

-- Flag modeled species & index the new column
UPDATE bien_species_native_status a
SET is_sdm_species=1 
FROM :TBL_SPP_RUN1 b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
CREATE INDEX bien_spp_native_status_is_sdm_spp_idx 
	ON bien_species_native_status (is_sdm_species);


