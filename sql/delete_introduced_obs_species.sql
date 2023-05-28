-- -------------------------------------------------------------------------------
-- Delete species whose data contains one or more known introduced observations
-- -------------------------------------------------------------------------------

--
-- Connect to schema
-- 

SET search_path TO :SCH_RMD;

--
-- Flag species with >=1 introduced observations
-- 

ALTER TABLE :TBL_SPP_RUN2
ADD COLUMN has_introduced_obs smallint default 0
;
UPDATE :TBL_SPP_RUN2 a
SET has_introduced_obs=1
FROM bien_species_native_status b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
AND b.native_status LIKE '%I%'
;
\set introduced_obs_idx :TBL_SPP_RUN2 _has_introduced_obs_idx
CREATE INDEX :introduced_obs_idx ON :TBL_SPP_RUN2(has_introduced_obs);

--
-- Summarize the result & save
-- 

-- Remove rows if any from previous runs of this script
DELETE FROM :TBL_STATS_RUN2
WHERE period LIKE '%introduced%'
;

INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before: introduced obs species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2 WHERE has_introduced_obs=1)::integer
;

/*
INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before filtering introduced obs  species'::text,
(SELECT COUNT(*) FROM :TBL_DATA_RUN2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2)::integer
;
*/

--
-- Delete intorduced obs species data and species
-- 

-- Delete data for has_introduced_obs species
DELETE 
FROM :TBL_DATA_RUN2 a  
USING :TBL_SPP_RUN2 b 
WHERE a.scrubbed_species_binomial = b.scrubbed_species_binomial
AND b.has_introduced_obs=1
;
-- Delete has_introduced_obs species
DELETE 
FROM :TBL_SPP_RUN2
WHERE has_introduced_obs=1
;

--
-- Summarize the results & save
-- 

INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'After filtering has_introduced_obs species'::text,
(SELECT COUNT(*) FROM :TBL_DATA_RUN2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2)::integer
;

--
-- Drop the temporary column
-- 

ALTER TABLE :TBL_SPP_RUN2
DROP COLUMN has_introduced_obs
;

