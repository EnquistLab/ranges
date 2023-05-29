-- -------------------------------------------------------------------------------
-- Delete species which occur in the NSR database
-- The goal is to keep species whose native status is unknown because they do 
-- not occur in any NSR checklist
-- -------------------------------------------------------------------------------

--
-- Connect to schema
-- 

SET search_path TO :SCH_RMD;

--
-- Flag species NOT in NSR; these are the ones we want to keep
-- 

ALTER TABLE :TBL_SPP_RUN2
ADD COLUMN is_in_nsr smallint default 1
;
UPDATE :TBL_SPP_RUN2 a
SET is_in_nsr=0
FROM bien_species_native_status b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
-- AND (b.native_status NOT LIKE '%I%')  
-- NO, the above is incorrect! Includes many we don't want. 
-- The following filter includes only species not in NSR.
AND (
native_status in ('A', 'A,UNK', 'UNK') or native_status is null
)
;
\set is_in_nsr_idx :TBL_SPP_RUN2 _is_in_nsr_idx
CREATE INDEX :is_in_nsr_idx ON :TBL_SPP_RUN2(is_in_nsr);

--
-- Summarize the result & save
-- 

-- Remove rows if any from previous runs of this script
DELETE FROM :TBL_STATS_RUN2
WHERE period LIKE '%NSR%'
;

INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'NSR species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2 WHERE is_in_nsr=1)::integer
;


--
-- Delete NSR species data and species
-- 

-- Delete data 
DELETE 
FROM :TBL_DATA_RUN2 a  
USING :TBL_SPP_RUN2 b 
WHERE a.scrubbed_species_binomial = b.scrubbed_species_binomial
AND b.is_in_nsr=1
;
-- Delete species
DELETE 
FROM :TBL_SPP_RUN2
WHERE is_in_nsr=1
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
'After filtering NSR species'::text,
(SELECT COUNT(*) FROM :TBL_DATA_RUN2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2)::integer
;

--
-- Drop the temporary column
-- 

ALTER TABLE :TBL_SPP_RUN2
DROP COLUMN is_in_nsr
;
