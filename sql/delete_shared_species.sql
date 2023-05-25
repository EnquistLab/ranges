-- -------------------------------------------------------------------------------
-- Delete species from model data run 1 that are shared with run 2 
-- 
-- Run 1 is observations of species where is_introduced=0 only, whereas
-- run 2 is observations of species where is_introduced=NULL. Only the
-- new species, not include in run 1, are needed for run 2.
-- -------------------------------------------------------------------------------

/* 
-- Aliases passed from calling script:
\set SCH_RMD range_data
\set TBL_SPP_RUN1 range_model_species_20230418
\set TBL_SPP_RUN2 range_model_species_20230524
\set TBL_DATA_RUN2 range_model_data_raw_20230524
\set TBL_STATS_RUN2 range_model_data_stats_20230524
*/


--
-- Connect to schema
-- 

SET search_path TO :SCH_RMD;

--
-- Flag shared species
-- 

ALTER TABLE :TBL_SPP_RUN2
ADD COLUMN is_in_run1 smallint default 0
;
UPDATE :TBL_SPP_RUN2 a
SET is_in_run1=1
FROM :TBL_SPP_RUN1 b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
\set IDX_SHARED_SPP :TBL_SPP_RUN2 _is_in_run1_idx
CREATE INDEX :IDX_SHARED_SPP ON :TBL_SPP_RUN2(is_in_run1);

--
-- Summarize the result & save
-- 

-- Remove rows if any from previous runs of this script
DELETE FROM :TBL_STATS_RUN2
WHERE period LIKE '%shared%'
;

INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before: shared species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2 WHERE is_in_run1=1)::integer
;
INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before filtering shared species'::text,
(SELECT COUNT(*) FROM :TBL_DATA_RUN2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2)::integer
;

--
-- Delete  shared species data and attributes
-- 

-- Delete data for shared species
DELETE 
FROM :TBL_DATA_RUN2 a  
USING :TBL_SPP_RUN2 b 
WHERE a.scrubbed_species_binomial = b.scrubbed_species_binomial
AND b.is_in_run1=1
;
-- Delete shared species
DELETE 
FROM :TBL_SPP_RUN2
WHERE is_in_run1=1
;

--
-- Run the count again
-- 

-- Flag shared species again (there shouldn't be any)
ALTER TABLE :TBL_SPP_RUN2
DROP COLUMN is_in_run1
;
ALTER TABLE :TBL_SPP_RUN2
ADD COLUMN is_in_run1 smallint default 0
;
UPDATE :TBL_SPP_RUN2 a
SET is_in_run1=1
FROM :TBL_SPP_RUN1 b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
CREATE INDEX :IDX_SHARED_SPP ON :TBL_SPP_RUN2(is_in_run1);

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
'After: shared species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2 WHERE is_in_run1=1)::integer
;
INSERT INTO :TBL_STATS_RUN2 (
period,
obs,
species_table_rows,
species
)
SELECT 
'After filtering shared species'::text,
(SELECT COUNT(*) FROM :TBL_DATA_RUN2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :TBL_SPP_RUN2)::integer
;

--
-- Drop the temporary column
-- 

ALTER TABLE :TBL_SPP_RUN2
DROP COLUMN is_in_run1
;

