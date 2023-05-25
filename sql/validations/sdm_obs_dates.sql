-- ------------------------------------------------------------------
-- Validations related to date and decade of observation for BIEN 4.2
-- SDM occurrence data and species
-- 
-- NOTE: Log in as "bien" so objects created are owned by "bien"
-- ------------------------------------------------------------------

\set adb analytical_db
\set bsr bien_species_richness
\set sdm_min_obs 10


\c vegbien
set search_path to :adb;

alter table range_model_data_raw
drop column if exists event_date,
drop column if exists event_year,
drop column if exists decade
;
alter table range_model_data_raw
add column event_date date default null,
add column event_year integer default null,
add column decade integer default null
;

-- Drop columns on target table to speed up update query
drop index range_model_data_raw_higher_plant_group_idx;
drop index range_model_data_raw_is_range_model_ob_202209_idx;
drop index range_model_data_raw_is_vasc_idx;
drop index range_model_data_raw_species_nospace_idx;
drop index range_model_data_raw_scrubbed_species_binomial_idx;

SET work_mem = '16GB';

update range_model_data_raw a
set event_date=b.event_date
from view_full_occurrence_individual b
where a.taxonobservation_id=b.taxonobservation_id
and b.event_date is not null
;

RESET work_mem;




SET work_mem = '16GB';

update range_model_data_raw a
set event_year=date_part('year', event_date)
where event_date is not null
;
update range_model_data_raw a
set decade=concat(left((event_year::text), 3), '0')::int
where event_year is not null
;



-- add back old indexes plus new
create index range_model_data_raw_higher_plant_group_idx on range_model_data_raw (higher_plant_group);
create index range_model_data_raw_is_range_model_ob_202209_idx on range_model_data_raw (is_range_model_ob_202209);
create index range_model_data_raw_is_vasc_idx on range_model_data_raw (is_vasc);
create index range_model_data_raw_species_nospace_idx on range_model_data_raw (species_nospace);
create index range_model_data_raw_scrubbed_species_binomial_idx on range_model_data_raw (scrubbed_species_binomial);
create index range_model_data_raw_event_date_idx on range_model_data_raw (event_date);
create index range_model_data_raw_event_year_idx on range_model_data_raw (event_year);


RESET work_mem;

--
-- Calculate summary stats for species by year
--

set search_path to :bsr;

SET work_mem = '16GB';


-- All observations per decade
drop table if exists sdm_obs_per_decade;
create table sdm_obs_per_decade as
select decade, count(*) as raw_obs
from :adb.range_model_data_raw
group by decade
order by decade desc
;

-- SDM-quality observations per species per decade
drop table if exists sdm_spp_obs_per_decade;
create table sdm_spp_obs_per_decade as
select scrubbed_species_binomial as species, taxonomic_status, decade, count(*) as raw_obs
from :adb.range_model_data_raw
where (is_introduced=0 or is_introduced is null)
group by scrubbed_species_binomial, taxonomic_status, decade
order by scrubbed_species_binomial, taxonomic_status, decade desc
;

RESET work_mem;

-- Aggregate points by 10km grid cells
-- See: https://gis.stackexchange.com/a/296823/159823







-- Add column indicating if obs are sufficient



-- Create species x decade crosstab
-- See: https://stackoverflow.com/a/11751905/2757825




-- export id+species+decade for native observations of accepted species
/* for testing:
\copy (select taxonobservation_id, species_nospace, decade from range_model_data_raw where taxonomic_status='Accepted' and is_introduced=0 LIMIT 100) TO '/tmp/range_model_data_raw_test.csv' WITH CSV HEADER;
*/
\copy (select taxonobservation_id, species_nospace, decade from range_model_data_raw where taxonomic_status='Accepted' and is_introduced=0) TO '/tmp/range_model_data_raw_test.csv' with csv header;
