#!/bin/bash

#########################################################################
# Load BIEN range model species (2022 run) from Cory to BIEN DB and
# add columns for taxonomic_status and higher_taxon
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
SCH_BIENDB="analytical_db"
SCH_WORKING="boyle"

# species input file name and ext
spp_infile="allSpeciesWithPresencesList.csv"

# Results file
spp_outfile="bienRangeSpeciesStatus.csv"

# Base directory
basedir="/home/boyle/bien"

# Where are generic functions, etc?
includesdir=$basedir"/includes/sh"

# Working directory (of this script)
wd=$basedir"/ranges"

# Load generic functions
source $includesdir"/functions.sh"	# Load functions file(s)

# Interactive mode on by default
i="true"
e="true"

# Process name for emails
pname="Load species"

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

echoi $i -n "Creating species table..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH_WORKING" -f "${wd}/sql/create_species_table.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Loading species..."
sql="\copy ${SCH_WORKING}.bien_ranges_species FROM '${wd}/${spp_infile}' WITH (FORMAT CSV)"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

echoi $i -n "Preparing species table..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH_WORKING" -f "${wd}/sql/alter_species_table.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Dumping species list as file..."
sql="\copy (SELECT species FROM ${SCH_WORKING}.bien_ranges_species ORDER BY species) TO '${wd}/bienspeciesmodeled' WITH (FORMAT CSV)"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

echoi $i "Populating taxonomic status and higher taxon by species:"
IFS_bak=$IFS
IFS=''
while read SPECIES
do
	echoi $i "- "$SPECIES
	PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCHW="$SCH_WORKING"  -v SCHB="$SCH_BIENDB" -v SPECIES="$SPECIES" -f "${wd}/sql/update_species_status.sql"
done < ${wd}/bienspeciesmodeled
IFS=$IFS_bak
source "${includesdir}/check_status.sh"

echoi $i -n "Dumping results to file..."
sql="\copy ${SCH_WORKING}.bien_ranges_species to '${wd}/${spp_outfile}' csv header"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

# 
# Send process completion message
#

source "${includesdir}/finish.sh"