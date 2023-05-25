-- ------------------------------------------------------------
-- Range model data validations
-- ------------------------------------------------------------

\c vegbien
\set adb analytical_db
\set bsr bien_species_richness

set search_path to :bsr;

select * from bien_species_obs_by_country where country='France' and (species like 'Vanilla%' or species like 'Cattleya%')
order by species;
/*
 country |     species      | is_accepted | is_vascular | is_native 
---------+------------------+-------------+-------------+-----------
 France  | Cattleya cernua  |           0 |           1 |         0
 France  | Cattleya trianae |           1 |           1 |         0
 France  | Vanilla bahiana  |           1 |           1 |         0
 France  | Vanilla palmarum |           1 |           1 |         0
(4 rows)
*/

select country, species, "filter.group", nsr_native_status
from ctry_species_sdm 
where country='France'
and (species like 'Vanilla%' or species like 'Cattleya%')
order by species
;
/*
 country |      species       | filter.group | nsr_native_status 
---------+--------------------+--------------+-------------------
 France  | Cattleya violacea  | rare         | absent
 France  | Vanilla guianensis | rare         | absent
 France  | Vanilla hartii     | rare         | absent
 France  | Vanilla hostmannii | rare         | absent
 France  | Vanilla mexicana   | rare         | absent
 France  | Vanilla odorata    | rare         | absent
 France  | Vanilla ovata      | rare         | absent
 France  | Vanilla planifolia | rare         | absent
 France  | Vanilla pompona    | rare         | absent
 France  | Vanilla wrightii   | rare         | absent
(10 rows)
*/

set search_path to :adb;

-- Checking for records of Cattleya or Vanilla in the raw range model data
select distinct scrubbed_species_binomial as species, count(*) as observations
from range_model_data_raw
where scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
)
group by species
order by species
;
/*
      species       | observations 
--------------------+--------------
 Cattleya violacea  |          110
 Vanilla guianensis |            5
 Vanilla hartii     |           11
 Vanilla hostmannii |            9
 Vanilla mexicana   |          128
 Vanilla odorata    |           70
 Vanilla ovata      |            2
 Vanilla planifolia |          509
 Vanilla pompona    |          117
 Vanilla wrightii   |           11
(10 rows)
*/

-- Checking for records of Cattleya or Vanialla from France in the raw observation data
select a.taxonobservation_id, a.scrubbed_species_binomial as species, a.latitude, a.longitude
from range_model_data_raw a join view_full_occurrence_individual b 
on a.taxonobservation_id=b.taxonobservation_id
where b.country='France' and a.scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
);
/*
 taxonobservation_id | species | latitude | longitude 
---------------------+---------+----------+-----------
(0 rows)
*/

-- As above, but widening our net to all of Europe:
select a.taxonobservation_id, a.scrubbed_species_binomial as species, b.country, a.latitude, a.longitude,
b.is_geovalid, b.is_cultivated_observation as is_cult, b.is_introduced
from range_model_data_raw a join view_full_occurrence_individual b 
on a.taxonobservation_id=b.taxonobservation_id
where b.continent='Europe' and ( a.scrubbed_species_binomial like 'Cattley%' or a.scrubbed_species_binomial like 'Vanilla%' );
/*
 taxonobservation_id |       species       | latitude  | longitude 
---------------------+---------------------+-----------+-----------
           278136312 | Cattleya mossiae    |  50.75558 |  6.077055
           278720195 | Cattleya loddigesii |    51.589 |     -0.07
           269057695 | Vanilla planifolia  | 49.414978 |   8.66714
           301834991 | Vanilla planifolia  |  40.86139 |  14.26278
           278136966 | Cattleya purpurata  |  50.75558 |  6.077055
*/

-- Same as above,  showing locality infor instead:
select a.taxonobservation_id, a.scrubbed_species_binomial as species, b.country,  
b.locality
from range_model_data_raw a join view_full_occurrence_individual b 
on a.taxonobservation_id=b.taxonobservation_id
where b.continent='Europe' and ( a.scrubbed_species_binomial like 'Cattley%' or a.scrubbed_species_binomial like 'Vanilla%' );
/*
 taxonobservation_id |       species       | latitude  | longitude 
---------------------+---------------------+-----------+-----------
           278136312 | Cattleya mossiae    |  50.75558 |  6.077055
           278720195 | Cattleya loddigesii |    51.589 |     -0.07
           269057695 | Vanilla planifolia  | 49.414978 |   8.66714
           301834991 | Vanilla planifolia  |  40.86139 |  14.26278
           278136966 | Cattleya purpurata  |  50.75558 |  6.077055
*/


-- Only one of the above species (Vanilla planarum) is in vfoi, and it is 
-- correctly marked as "cultivated", so would not have made it into
-- range model data. Actually, none of these would have made it into sdm 
-- data as they are all is_geovalid=0
select country, scrubbed_species_binomial as species, latitude, longitude, is_geovalid, is_centroid, is_cultivated_observation as is_cult, is_introduced, LEFT(locality, 50) AS locality_description
from view_full_occurrence_individual
where country='France' and scrubbed_genus IN ('Vanilla','Cattleya')
;
/*
 country |     species      | latitude | longitude | is_geovalid | is_centroid | is_cult | is_introduced 
---------+------------------+----------+-----------+-------------+-------------+---------+---------------
 France  | Vanilla palmarum |          |           |           0 |           0 |       1 |             1
 France  | Vanilla bahiana  |          |           |           0 |           0 |       1 |             1
 France  | Vanilla bahiana  |          |           |           0 |           0 |         |             1
 France  | Cattleya trianae |          |           |           0 |           0 |         |             1
 France  | Cattleya trianae |          |           |           0 |           0 |         |             1
 France  | Cattleya cernua  |          |           |           0 |           0 |         |             1
(6 rows)
*/

-- And indeed, none are in range model data
select country, a.scrubbed_species_binomial as species, is_geovalid, is_centroid, is_cultivated_observation as is_cult, a.is_introduced 
from view_full_occurrence_individual a join range_model_data_raw b 
on a.taxonobservation_id=b.taxonobservation_id 
where a.country='France' and scrubbed_genus IN ('Vanilla','Cattleya')
;
/*
 country | species | is_geovalid | is_centroid | is_cult | is_introduced 
---------+---------+-------------+-------------+---------+---------------
(0 rows)
*/

-- Finally, let's check a hunch that some or all of these occurrences might have from from French West Indies islands erroneously labeled as France:
select distinct scrubbed_species_binomial as species
from view_full_occurrence_individual a join country b
on a.country=b.country
where b.iso_alpha3 in (
'GLP','MTQ','BLM','MAF','GUF'
)
and scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
);
select distinct scrubbed_species_binomial as species
from view_full_occurrence_individual a join country b
on a.country=b.country
where (b.is_caribbean=1 or b.iso_alpha3='GUF')
and scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
);




select taxonobservation_id, scrubbed_species_binomial as species, a.country, is_geovalid, is_cultivated_observation as is_cult, a.is_introduced 
from view_full_occurrence_individual a join country b
on a.country=b.country
where b.iso_alpha3 in (
'GLP','MTQ','BLM','MAF'
)
and scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
);


-- Checking French West Indies + French Guiana
select a.scrubbed_species_binomial as species, a.country, count(*) as observations 
from view_full_occurrence_individual a join country b
on a.country=b.country
join range_model_data_raw c 
on a.taxonobservation_id=c.taxonobservation_id 
where b.iso_alpha3 in (
'GLP','MTQ','BLM','MAF','GUF'
)
and a.scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
)
group by species, a.country
order by species, a.country
;

-- Adding French Polynesia
select a.scrubbed_species_binomial as species, a.country, count(*) as observations 
from view_full_occurrence_individual a join country b
on a.country=b.country
join range_model_data_raw c 
on a.taxonobservation_id=c.taxonobservation_id 
where b.iso_alpha3 in (
'GLP','MTQ','BLM','MAF','GUF','PYF','ATF'
)
and a.scrubbed_species_binomial in (
'Cattleya violacea',
'Vanilla guianensis',
'Vanilla hartii',
'Vanilla hostmannii',
'Vanilla mexicana',
'Vanilla odorata',
'Vanilla ovata',
'Vanilla planifolia',
'Vanilla pompona',
'Vanilla wrightii'
)
group by species, a.country
order by species, a.country
;

-- Where are observations of Cattleya violacea from?
select a.scrubbed_species_binomial as species, a.country, count(*) as observations 
from view_full_occurrence_individual a join country b
on a.country=b.country
join range_model_data_raw c 
on a.taxonobservation_id=c.taxonobservation_id 
where a.scrubbed_species_binomial='Cattleya violacea'
group by species, a.country
order by species, a.country
;
/*
      species      |  country  | observations 
-------------------+-----------+--------------
 Cattleya violacea | Bolivia   |            1
 Cattleya violacea | Brazil    |           58
 Cattleya violacea | Colombia  |           32
 Cattleya violacea | Ecuador   |            5
 Cattleya violacea | Guyana    |            4
 Cattleya violacea | Venezuela |           10
(6 rows)
*/

-- None of the observations are from French Territories, but it's quite likely the SDM
-- could have spilled over into French Guiana


