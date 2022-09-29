-- ----------------------------------------------------------------------------
-- Make temporary temp tables for manual testing of 2022-09 range model 
-- queries only
-- ----------------------------------------------------------------------------

--
-- Make the temp tables
--

drop table if exists range_model_data_raw_test;
create table range_model_data_raw_test (like range_model_data_raw including all);
insert into range_model_data_raw_test select * from range_model_data_raw limit 100;
alter table range_model_data_raw_test owner to bien;

drop table if exists range_model_data_metadata_test;
create table range_model_data_metadata_test (like range_model_data_metadata including all);
insert into range_model_data_metadata_test 
select distinct a.* from range_model_data_metadata a JOIN range_model_data_raw_test b
ON a.scrubbed_species_binomial=b.scrubbed_species_binomial
;
alter table range_model_data_metadata_test owner to bien;


--
-- Remove tables when you're done
--

drop table if exists range_model_data_raw_test;
drop table if exists range_model_data_metadata_test;
