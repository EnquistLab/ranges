-- ---------------------------------------------------------
-- Populate taxonomic status and higher taxon by joining to 
-- vfoi on species
-- ---------------------------------------------------------

SET search_path TO :SCHW;

UPDATE bien_ranges_species a
SET taxonomic_status=b.scrubbed_taxonomic_status,
higher_taxon=b.higher_plant_group
FROM :SCHB.view_full_occurrence_individual b
WHERE a.species=:'SPECIES'
AND b.scrubbed_species_binomial=:'SPECIES'
;
