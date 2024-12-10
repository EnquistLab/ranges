-- -----------------------------------------------------------------
-- Combine species attribute tables "range_model_species_20230524"
-- and "range_model_species_20230524_missing_spp" into single table
-- "range_model_species_20230524_all"
-- -----------------------------------------------------------------

/* MANUAL OPERATION. Standalone script, not part of any pipeline. */

SET search_path TO ranges_data;

CREATE TABLE range_model_species_20230524_all (LIKE range_model_species_20230524 INCLUDING ALL)
;

INSERT INTO range_model_species_20230524_all
SELECT * FROM range_model_species_20230524
;

INSERT INTO range_model_species_20230524_all
SELECT * FROM range_model_species_20230524_missing_spp
;

-- Drop indexes and rebuild, just in case
DROP INDEX range_model_species_20230524_all_scrubbed_species_binomial_idx;
DROP INDEX range_model_species_20230524_all_scrubbed_species_binomial_idx1;
CREATE INDEX range_model_species_20230524_all_scrubbed_species_binomial_idx 
ON range_model_species_20230524_all (scrubbed_species_binomial);

--
-- Validations
--

SELECT EXISTS (
SELECT scrubbed_species_binomial, COUNT(*)
FROM range_model_species_20230524_all
GROUP BY scrubbed_species_binomial
HAVING COUNT(*)>1
) AS "HAS_NON_UNIQUE_SPECIES"
;

-- Export CSV file
\copy (SELECT * FROM range_data.range_model_species_20230524_all ORDER BY species_nospace ) to '/tmp/range_model_species_20230524_all.csv' csv header


/* In the shell:

mv /tmp/range_model_species_20230524_all.csv /home/boyle/bien/ranges_data/data/range_model_species_20230524_all.csv
cd ~/bien/ranges_data/data
zip range_model_species_20230524_all.csv.zip range_model_species_20230524_all.csv
rm range_model_species_20230524_all.csv

*/
