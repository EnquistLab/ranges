-- -------------------------------------------------------------------
-- Extract range model species attribute table
-- Early version, keeping so earlier scripts can run
-- -------------------------------------------------------------------

SET search_path TO :SCH;

DROP TABLE IF EXISTS :TBL_RMS;
CREATE TABLE :TBL_RMS AS
SELECT DISTINCT scrubbed_species_binomial, species_nospace, taxonomic_status, 
higher_plant_group, is_vasc
FROM :TBL_RMD
ORDER BY scrubbed_species_binomial
;

ALTER TABLE :TBL_RMS
ADD COLUMN family text,
ADD COLUMN growth_form text
;

UPDATE :TBL_RMS a
SET 
family=b.family,
growth_form=b.gf
FROM species_growth_forms b
WHERE a.scrubbed_species_binomial=b.species
;
