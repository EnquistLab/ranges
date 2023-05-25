-- ---------------------------------------------------------------------
-- Update table country with flags for Caribbean, Lesser Antilles and French West Indies
-- ---------------------------------------------------------------------

\set adb analytical_db

\c vegbien
set search_path to :adb;

alter table country 
add column is_caribbean integer default 0, 
add column is_lesser_antilles integer default 0,
add column is_french_westindies integer default 0
;

UPDATE country
SET is_caribbean=1
WHERE iso_alpha3 in (
'AIA',
'ATG',
'ABW',
'BHS',
'BRB',
'BMU',
'BES',
'VGB',
'CYM',
'CUB',
'CUW',
'DMA',
'DOM',
'GRD',
'GLP',
'HTI',
'JAM',
'MTQ',
'MSR',
'PRI',
'BLM',
'KNA',
'LCA',
'MAF',
'VCT',
'SXM',
'TTO',
'TCA',
'VIR'
);

UPDATE country
SET is_lesser_antilles=1
WHERE iso_alpha3 in (
'AIA',
'ATG',
'ABW',
'BRB',
'BES',
'VGB',
'CUW',
'DMA',
'GLP',
'MTQ',
'MSR',
'PRI',
'BLM',
'KNA',
'LCA',
'MAF',
'VCT',
'SXM',
'TTO',
'VIR'
);

UPDATE country
SET is_lesser_antilles=1
WHERE iso_alpha3 in (
'GLP',
'MTQ',
'BLM',
'MAF'
);
