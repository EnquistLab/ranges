-- -----------------------------------------------------------------------
-- Compare species extract in model data runs from 20230418 and 20230524
-- to ensure no overlap. The first run includes observations of species
-- where is_introduced=0 only. The second includes species where 
-- is_introduced=NULL
-- -----------------------------------------------------------------------

--
-- Set aliases
-- 

\set tbl_spp_run1 range_model_species_20230418
\set tbl_spp_run2 range_model_species_20230524
\set idx_shared_spp :tbl_spp_run2 _is_in_run1_idx
\set tbl_data_run2 range_model_data_raw_20230524
\set tbl_stats range_model_data_stats_20230524

--
-- Connect to db & schema
-- 

\c vegbien
SET search_path TO range_data;

--
-- Flag shared species
-- 

ALTER TABLE :tbl_spp_run2
ADD COLUMN is_in_run1 smallint default 0
;
UPDATE :tbl_spp_run2 a
SET is_in_run1=1
FROM :tbl_spp_run1 b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
CREATE INDEX :idx_shared_spp ON :tbl_spp_run2(is_in_run1);

--
-- Summarize the result & save
-- 

-- Remove rows if any from previous runs of this script
DELETE FROM :tbl_stats
WHERE period LIKE '%shared%'
;

INSERT INTO :tbl_stats (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before: shared species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :tbl_spp_run2 WHERE is_in_run1=1)::integer
;
INSERT INTO :tbl_stats (
period,
obs,
species_table_rows,
species
)
SELECT 
'Before filtering shared species'::text,
(SELECT COUNT(*) FROM :tbl_data_run2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :tbl_spp_run2)::integer
;

--
-- Delete  shared species data and attributes
-- 

-- Delete data for shared species
DELETE 
FROM :tbl_data_run2 a  
USING :tbl_spp_run2 b 
WHERE a.scrubbed_species_binomial = b.scrubbed_species_binomial
AND b.is_in_run1=1
;
-- Delete shared species
DELETE 
FROM :tbl_spp_run2
WHERE is_in_run1=1
;

--
-- Run the count again
-- 

-- Flag shared species again (there shouldn't be any)
ALTER TABLE :tbl_spp_run2
DROP COLUMN is_in_run1
;
ALTER TABLE :tbl_spp_run2
ADD COLUMN is_in_run1 smallint default 0
;
UPDATE :tbl_spp_run2 a
SET is_in_run1=1
FROM :tbl_spp_run1 b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
CREATE INDEX :idx_shared_spp ON :tbl_spp_run2(is_in_run1);

--
-- Summarize the results & save
-- 

INSERT INTO :tbl_stats (
period,
obs,
species_table_rows,
species
)
SELECT 
'After: shared species'::text,
NULL,
NULL,
(SELECT COUNT(*)::integer FROM :tbl_spp_run2 WHERE is_in_run1=1)::integer
;
INSERT INTO :tbl_stats (
period,
obs,
species_table_rows,
species
)
SELECT 
'After filtering shared species'::text,
(SELECT COUNT(*) FROM :tbl_data_run2)::integer,
NULL,
(SELECT COUNT(*)::integer FROM :tbl_spp_run2)::integer
;

--
-- Drop the temporary column
-- 

ALTER TABLE :tbl_spp_run2
DROP COLUMN is_in_run1
;

