-- -------------------------------------------------------------------------
-- Flag species and observations for species names with >1 taxonomic status
-- -------------------------------------------------------------------------

SET search_path TO :SCH_RMD;

-- Create temporary table of all species binomials and their associated taxonomic status
/*
Note that taxonomic_status may refer to a subspecies or variety rather than
the listed species. This doesn't matter. The goal is to removed observations 
of unresolved taxa *only* where there is a conflict, with the same canonical
name appearing as both accepted and unresolved. Basically, if a name has 
conflicting taxonomic status, we ignore (remove) the observations associated 
with the unresolved name. If all instances of the name are unresolved, we keep
that name and all its observations. 
*/
DROP TABLE IF EXISTS range_model_species_temp;
CREATE TABLE range_model_species_temp AS
-- SELECT DISTINCT scrubbed_species_binomial, taxonomic_status
SELECT DISTINCT scrubbed_species_binomial, species_nospace, taxonomic_status
FROM :TBL_RMD
ORDER BY scrubbed_species_binomial
;

-- Extract multi-status species only
DROP TABLE IF EXISTS multistatus_species;
CREATE TABLE multistatus_species AS
SELECT scrubbed_species_binomial FROM (
SELECT scrubbed_species_binomial, COUNT(*) AS rows 
FROM range_model_species_temp
GROUP BY scrubbed_species_binomial 
HAVING COUNT(*)>1
) a;

ALTER TABLE multistatus_species
ADD PRIMARY KEY (scrubbed_species_binomial)
;

-- Save before counts to table range_model_data_stats_${run}
DROP TABLE IF EXISTS :TBL_RMDS;
CREATE TABLE :TBL_RMDS AS
SELECT 
'Before'::text AS period,
(SELECT COUNT(*) FROM :TBL_RMD)::integer AS obs,
(SELECT COUNT(*) FROM range_model_species_temp)::integer AS species_table_rows,
(SELECT COUNT(DISTINCT scrubbed_species_binomial)::integer FROM range_model_species_temp)::integer AS species
;

-- Mark for deletion all observations where species is multi-status
-- AND scrubbed_taxonomic_status='Unresolved' or 'No opinion'
\set TBL_RMD_TS_IDX :TBL_RMD'_taxonomic_status_idx'
CREATE INDEX :TBL_RMD_TS_IDX ON :TBL_RMD(taxonomic_status);

ALTER TABLE :TBL_RMD
ADD COLUMN delete smallint DEFAULT 0
;
UPDATE :TBL_RMD a
SET delete=1
FROM multistatus_species b
WHERE a.scrubbed_species_binomial=b.scrubbed_species_binomial
AND a.taxonomic_status<>'Accepted'
;

-- Delete the offending observations
\set TBL_RMD_DEL_IDX :TBL_RMD'_delete_idx'
CREATE INDEX :TBL_RMD_DEL_IDX ON :TBL_RMD (delete);

DELETE FROM :TBL_RMD
WHERE delete=1
;

-- Tidy up
DROP TABLE range_model_species_temp, multistatus_species;
ALTER TABLE :TBL_RMD DROP COLUMN delete;
