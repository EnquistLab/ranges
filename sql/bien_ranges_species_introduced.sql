-- -----------------------------------------------------------
-- Create new table of bien ranges species with added columns
-- filter_group and obs_introduced, for filtering out species
-- with excessive number of introduced observations
--
-- Table :tbl_spp in schema bien_species_richness must exist.
--
-- Date: 18 Sept. 2022
-- -----------------------------------------------------------

\c vegbien
SET search_path TO bien_species_richness;

\set sch_adb analytical_db
\set tbl_spp bien_species
\set tbl_spp_pk bien_species_pkey

/* For testing only 
\set tbl_spp bien_species_test
\set tbl_spp_pk bien_species_test_pkey
drop table if exists :tbl_spp;
create table :tbl_spp (like bien_species including all);
insert into :tbl_spp select * from bien_species limit 100;
*/

-- Make sure species is PK in the following tables
ALTER TABLE :tbl_spp DROP CONSTRAINT IF EXISTS :tbl_spp_pk;
ALTER TABLE :tbl_spp ADD PRIMARY KEY (species);

ALTER TABLE :sch_adb.range_model_data_metadata DROP CONSTRAINT IF EXISTS range_model_data_metadata_pkey;
ALTER TABLE :sch_adb.range_model_data_metadata ADD PRIMARY KEY (scrubbed_species_binomial);

ALTER TABLE :sch_adb.species_observation_counts_crosstab DROP CONSTRAINT IF EXISTS species_observation_counts_crosstab_pkey;
ALTER TABLE :sch_adb.species_observation_counts_crosstab ADD PRIMARY KEY (species);


ALTER TABLE :tbl_spp
ADD COLUMN growth_form text,		-- add this while we're at it
ADD COLUMN growth_form_conf text,	
ADD COLUMN is_ranges_species smallint default 0,
ADD COLUMN filter_group text,
ADD COLUMN obs_ranges_common integer default NULL,  -- common: filters 1-8 (all)
ADD COLUMN obs_ranges_rare integer default NULL,	-- rare: filters 1-6 (omit 7 & 8)
ADD COLUMN obs_ranges_rare_native integer default NULL,	-- rare, native only: filters 1-7
ADD COLUMN obs_ranges integer default NULL,
ADD COLUMN obs_ranges_introduced integer default NULL
;

-- Populate growth form
UPDATE :tbl_spp a
SET 
growth_form=b.gf,
growth_form_conf=b.gf_conf_flag
FROM :sch_adb.species_growth_forms b
WHERE a.species=b.species
;

-- Populate filter group (rare or common)
UPDATE :tbl_spp a
SET 
is_ranges_species=1,
filter_group=b.filter_group
FROM :sch_adb.range_model_data_metadata b
WHERE a.species=b.scrubbed_species_binomial
;

-- Populate observation counts by filter group
UPDATE :tbl_spp a
SET 
obs_ranges_common=b."8. observation_type", 
obs_ranges_rare=b."6. year>=1970",	
obs_ranges_rare_native=b."7. is_introduced"	
FROM :sch_adb.species_observation_counts_crosstab b
WHERE a.species=b.species
;

-- Populate introduced observations
DROP INDEX IF EXISTS bien_species_is_ranges_species_idx;
CREATE INDEX bien_species_is_ranges_species_idx ON :tbl_spp(is_ranges_species);

UPDATE :tbl_spp
SET obs_ranges_introduced = obs_ranges_rare - obs_ranges_rare_native
WHERE is_ranges_species=1
;
UPDATE :tbl_spp
SET obs_ranges_introduced = 0
WHERE is_ranges_species=1 AND filter_group='common'
;

-- Populate total observations
DROP INDEX IF EXISTS bien_species_filter_group_idx;
CREATE INDEX bien_species_filter_group_idx ON :tbl_spp(filter_group);

UPDATE :tbl_spp
SET obs_ranges=
CASE
WHEN filter_group='common' THEN obs_ranges_common
WHEN filter_group='rare' THEN obs_ranges_rare
ELSE NULL
END
;

-- Simplified table, omitting intermediate calculations
DROP TABLE IF EXISTS bien_ranges_species;
CREATE TABLE bien_ranges_species AS
SELECT 
species,
genus,
family,
growth_form,
growth_form_conf,	
taxonomic_status,
higher_plant_group,
is_vascular,
filter_group,
obs_ranges AS obs_total,
obs_ranges_introduced AS obs_introduced
FROM :tbl_spp 
WHERE is_ranges_species=1 AND taxonomic_status='Accepted'
ORDER BY species
;

-- Dump the results to file
COPY bien_ranges_species TO '/tmp/bien_ranges_species.csv' DELIMITER ',' CSV HEADER;

/* In the shell:

sudo mv /tmp/bien_ranges_species.csv /home/bien/ranges/data/
sudo cp /home/bien/ranges/data/bien_ranges_species.csv /var/www/html/bien/data/
sudo chown boyle /var/www/html/bien/data/bien_ranges_species.csv
sudo chgrp www-data /var/www/html/bien/data/bien_ranges_species.csv
sudo zip /var/www/html/bien/data/bien_ranges_species.csv.zip /var/www/html/bien/data/bien_ranges_species.csv
sudo rm /var/www/html/bien/data/bien_ranges_species.csv
*/








