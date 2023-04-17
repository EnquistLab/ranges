-- 
-- Examine attributes of observations of species names with >1 taxonomic status
--

\c vegbien
set search_path to boyle;

/* Create index on range model species table if not already present
set search_path to analytical_db;

create index range_model_species_20230411_scrubbed_species_binomial_idx ON range_model_species_20230411(scrubbed_species_binomial);
*/

DROP TABLE IF EXISTS multistatus_species;
CREATE TABLE multistatus_species AS
SELECT scrubbed_species_binomial FROM (
SELECT scrubbed_species_binomial, COUNT(*) AS rows 
FROM analytical_db.range_model_species_20230411 
GROUP BY scrubbed_species_binomial 
HAVING COUNT(*)>1
) a;

ALTER TABLE multistatus_species
ADD PRIMARY KEY (scrubbed_species_binomial)
;

-- Extract taxonomic data for all obs of species with >1 taxonomic status
DROP TABLE IF EXISTS multistatus_species_obs;
CREATE TABLE multistatus_species_obs AS
SELECT taxonobservation_id, scrubbed_family, scrubbed_species_binomial, scrubbed_taxon_name_no_author, scrubbed_author, scrubbed_taxonomic_status 
FROM analytical_db.view_full_occurrence_individual 
WHERE scrubbed_species_binomial IN (
SELECT scrubbed_species_binomial FROM multistatus_species
);

DROP INDEX IF EXISTS multistatus_species_obs_scrubbed_species_binomial_idx;
DROP INDEX IF EXISTS multistatus_species_obs_scrubbed_taxon_name_no_author_idx;
CREATE INDEX multistatus_species_obs_scrubbed_species_binomial_idx ON multistatus_species_obs (scrubbed_species_binomial);
CREATE INDEX multistatus_species_obs_scrubbed_taxon_name_no_author_idx ON multistatus_species_obs (scrubbed_taxon_name_no_author);

-- extract only records where taxon is a species
-- Omit author to avoid including author spelling variants of the same accepted species
-- We only want binomials with >1 taxonomic status
DROP TABLE IF EXISTS multistatus_species_obs_species;
CREATE TABLE multistatus_species_obs_species AS
SELECT DISTINCT scrubbed_family, scrubbed_species_binomial, scrubbed_taxon_name_no_author, scrubbed_taxonomic_status 
FROM multistatus_species_obs
WHERE scrubbed_species_binomial=scrubbed_taxon_name_no_author
;

CREATE INDEX multistatus_species_obs_species_scrubbed_species_binomial_idx ON multistatus_species_obs_species (scrubbed_species_binomial);

-- Now extract all distinct taxa from the observations table, but only for 
-- taxa with species binomials with >1 taxonomic status
DROP TABLE IF EXISTS multistatus_species_conflicting;
CREATE TABLE multistatus_species_conflicting AS
SELECT DISTINCT a.scrubbed_family, a.scrubbed_species_binomial, scrubbed_taxon_name_no_author, a.scrubbed_author,
a.scrubbed_taxonomic_status
FROM multistatus_species_obs a JOIN (
SELECT scrubbed_species_binomial, COUNT(*) AS rows
FROM multistatus_species_obs_species
GROUP BY scrubbed_species_binomial
HAVING COUNT(*)>1
) b
ON a.scrubbed_species_binomial=b.scrubbed_species_binomial
ORDER BY a.scrubbed_species_binomial
;

