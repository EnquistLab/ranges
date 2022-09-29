-- ---------------------------------------------------------
-- Add fields to be populated and populate species without
-- underline
-- ---------------------------------------------------------

SET search_path TO :SCH;

ALTER TABLE bien_ranges_species
ADD COLUMN species text,
ADD COLUMN taxonomic_status text,
ADD COLUMN higher_taxon text
;

UPDATE bien_ranges_species
SET species=REPLACE(species_ul, '_', ' ')
;

DROP INDEX IF EXISTS bien_ranges_species_species_idx;
CREATE INDEX bien_ranges_species_species_idx ON bien_ranges_species(species);
