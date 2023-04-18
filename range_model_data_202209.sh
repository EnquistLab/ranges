#!/bin/bash

#########################################################################
# Add species attributes to BIEN 4.2 range model data, including native
# status from vfoi, and extract data and metadata tables September 2022 
# modeling run
#
# Notes:
#  1. Observations for each species saved to separate file (make sure containing
#     directory exists)
#  2. Species attributes save to single, separate file
#
# Requires existing tables: 
#  * range_model_data_raw
#  * range_model_data_metadata
#########################################################################

# Comment-block tags - Use for all temporary comment blocks

#### TEMP ####
# echo "WARNING: portions of script `basename "$BASH_SOURCE"` commented out!"
## Start comment block
# : <<'COMMENT_BLOCK_xxx'

## End comment block
# COMMENT_BLOCK_xxx
#### TEMP ####


#
# Parameters
#

# Database params
DB="vegbien"
USER="bien"
SCH="analytical_db"

# Range model metadata file
# Note: individual species data in separate files [Genus]_[species].csv
spp_meta_outfile="bien_ranges_species_attributes_202209.csv"

# Base directory
basedir="/home/boyle/bien"

# Where are generic functions, etc?
includesdir=$basedir"/includes/sh"

# Working directory 
wd=$basedir"/ranges"

# Source code base directory (this script)
srcdir=$wd"/src"

# input data directory 
datadir=$wd"/data"

# range model data base directory 
rm_datadir=$datadir"/rm_data_202209"

# range model species data directory 
rmspp_datadir=$rm_datadir"/species"

# Load generic functions
source $includesdir"/functions.sh"	# Load functions file(s)

# Interactive mode on by default
i="true"
e="true"

# Process name for emails
pname="Extract 09/2022 range model data"

# Email address for notifications
email="bboyle@email.arizona.edu"

# Send mail parameter ("true"|"false")
m="false"

#
# confirm operation and send email
#

startup_msg="Run process \""$pname"\"?"
confirm "$startup_msg";

# Start timing & process ID
start=`date +%s%N`; prev=$start
pid=$$

# Send notification email if this option set
#source "$includesdir/mail_process_start.sh"	# Email notification

echo ""; echo "------ Begin process '$pname' ------"
echo ""

source "${includesdir}/mail_process_start.sh"

# 
# Main
#

### TEMP ####
echo "WARNING: portions of script `basename "$BASH_SOURCE"` commented out!"
# Start comment block
: <<'COMMENT_BLOCK_1'




echoi $i -n "Altering range model data tables..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH" -f "${srcdir}/sql/alter_tables_range_model_data.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Loading species attributes..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH" -f "${srcdir}/sql/update_species_attributes.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Dumping all species names to file..."
sql="\copy (SELECT DISTINCT scrubbed_species_binomial FROM ${SCH}.range_model_data_raw ORDER BY scrubbed_species_binomial) TO '${rm_datadir}/bien_ranges_species_all' WITH (FORMAT CSV)"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"




# End comment block
COMMENT_BLOCK_1
### TEMP ####


echoi $i -n "Populating species native status: "
IFS_bak=$IFS
IFS=''
while read SPECIES
do
	echo -ne "\rPopulating species native status: "$SPECIES"            "
	lastspecies=$SPECIES
	PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SPECIES="$SPECIES" -f "${srcdir}/sql/update_species_native_status.sql"
done < ${rm_datadir}/bien_ranges_species_all
IFS=$IFS_bak
echo -ne "\rPopulating species native status: "$lastspecies"..."
source "${includesdir}/check_status.sh"

echoi $i -n "Marking range model observations..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH" -f "${srcdir}/sql/flag_sdm_obs.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Dumping range species names to file..."
sql="\copy (SELECT DISTINCT scrubbed_species_binomial FROM ${SCH}.range_model_data_raw WHERE is_range_model_ob_202209=1 ORDER BY scrubbed_species_binomial) TO '${rm_datadir}/bien_ranges_species_202209' WITH (FORMAT CSV)"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

# Dump range model data, one file per species, no header
echoi $i -n "Dumping range model data by species: "
while read SPECIES
do
	species_ns="${SPECIES// /_}"
	f_species="${species_ns}.csv"
	echo -ne "\rDumping range model data by species: "$species_ns"            "
	lastspecies=$species_ns
sql="\copy (SELECT taxonobservation_id, species_nospace AS species, latitude, longitude FROM ${SCH}.range_model_data_raw WHERE species_nospace='${species_ns}' AND is_range_model_ob_202209=1 ORDER BY taxonobservation_id) to '${rmspp_datadir}/${f_species}' csv "
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
done < ${rm_datadir}/bien_ranges_species_202209
echo -ne "\rDumping range model data by species: "$lastspecies"..."
source "${includesdir}/check_status.sh"

# Dump range model species attribute file, CSV with header
echoi $i -n "Exporting range model species attributes file..."
sql="\copy (SELECT species_nospace AS species, family, filter_group, taxonomic_status, higher_plant_group, is_vasc, gf AS growth_form FROM ${SCH}.range_model_data_metadata WHERE is_range_model_species_202209=1 ORDER BY species_nospace ) to '${rm_datadir}/${spp_meta_outfile}' csv header"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

# 
# Send process completion message
#

source "${includesdir}/finish.sh"