#!/bin/bash

#########################################################################
# Extract BIEN 4.2 range model data and extract data and metadata tables 
# for December 2022 modeling run
#
# Notes:
#  1. Observations for each species saved to separate file (make sure containing
#     directory exists)
#  2. Species attributes saved to single, separate file
#  3. Directories $rm_datadir and $rmspp_datadir must exist
#  4. Same as November 2022 run, except is_introduced=1 only (no nulls)
#
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
# Get command line parameters
#  

# Set defaults
i="true"						# Interactive mode on by default
e="true"						# Echo on by default
verbose="false"					# Minimal progress output

# Get options
while [ "$1" != "" ]; do
    case $1 in
        -n | --nowarnings )		i="false"
        						;;
        -v | --verbose )		verbose="true"
        						;;
        -s | --silent )			e="false"
        						i="false"
        						;;
        -m | --mail )         	m="true"
                                ;;
        * )                     echo "invalid option!"; exit 1
    esac
    shift
done

#
# Parameters
#

# Email address for notifications
# You must supply command line parameter -m to use this
email="bboyle@email.arizona.edu"

# LIMIT clause for testing only
# Set to empty string for production run 
LIMIT=100
LIMIT=""

# Database params
DB="vegbien"
SCH="analytical_db"
USER="bien"

# Range model data table
TBL_RMD="range_model_data_raw_202212"

# Range model species table
TBL_RMS="range_model_species_202212"

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
rm_datadir=$datadir"/rm_data_202212"

# range model species data directory 
rmspp_datadir=$rm_datadir"/species"

#
# END Parameters. Remaining parameters set automatically.
#

if [ "$LIMIT" == "" ]; then
	LIMITCLAUSE=""
else
	LIMITCLAUSE=" LIMIT ${LIMIT} "
fi

# Range model metadata file
# Note: individual species data in separate files [Genus]_[species].csv
sdm_spp_outfile="${TBL_RMS}.csv"

# Load generic functions
source $includesdir"/functions.sh"	# Load functions file(s)

# Process name for emails
pname="Extract December 2022 range model data"

#
# confirm operation and send email
#

# startup_msg="Run process \""$pname"\"?"
# confirm "$startup_msg";

if [ "$LIMIT" == "" ]; then
	runtype="production"
	limit_disp="[no limit]"
else
	runtype="test"
	limit_disp="$LIMIT"
fi


if [[ "$i" = "true" && -z ${master+x} ]]; then 

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Starting process '$pname' with the following parameters: 
	
	Database:		$DB
	Schema:			$SCH
	User:			$USER
	Raw data table:		$TBL_RMD
	Raw species table:	$TBL_RMS
	Species file:		$sdm_spp_outfile
	Model data dir: 	$rm_datadir
	Species data dir: 	$rmspp_datadir
	Run type:		$runtype
	Record limit:		$limit_disp
EOF
	)"		
	confirm "$msg_conf"
fi



# Start timing & process ID
start=`date +%s%N`; prev=$start
pid=$$

# Send notification email if this option set
#source "$includesdir/mail_process_start.sh"	# Email notification

echo ""; echo "------ Begin process '$pname' ------"
echo ""

if [ "$m" == "true" ]; then
	source "${includesdir}/mail_process_start.sh"
fi

# 
# Main
#

echoi $i -n "Extracting range model data to table ${TBL_RMD}..."

# Set index names
TBL_RMD_SSB_IDX="${TBL_RMD}_scrubbed_species_binomial_idx"
TBL_RMD_SNS_IDX="${TBL_RMD}_species_nospace_idx"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH" -v TBL_RMD="${TBL_RMD}" -v TBL_RMD_SSB_IDX="${TBL_RMD_SSB_IDX}" -v TBL_RMD_SNS_IDX="${TBL_RMD_SNS_IDX}" -v LIMITCLAUSE="${LIMITCLAUSE}" -f "${srcdir}/sql/range_model_data_raw_202212.sql"
source "${includesdir}/check_status.sh"

echoi $i -n "Extracting range model species to table ${TBL_RMS}..."
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -v SCH="$SCH" -v TBL_RMD="${TBL_RMD}" -v TBL_RMS="${TBL_RMS}" -f "${srcdir}/sql/range_model_species.bak.sql"
source "${includesdir}/check_status.sh"
echoi $i -n "Dumping range model species to file..."
sql="\copy (SELECT DISTINCT species_nospace FROM ${SCH}.${TBL_RMD} ORDER BY species_nospace) TO '${rm_datadir}/bien_ranges_species' WITH (FORMAT CSV)"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

# Dump range model data, one file per species, no header
echoi $i -n "Dumping range model data by species: "
while read SPECIES
do
	#species_ns="${SPECIES// /_}"
	f_species="${SPECIES}.csv"
	echo -ne "\rDumping range model data by species: ${SPECIES}            "
	lastspecies=$SPECIES
sql="\copy (SELECT taxonobservation_id, species_nospace AS species, latitude, longitude FROM ${SCH}.${TBL_RMD} WHERE species_nospace='${SPECIES}' ORDER BY taxonobservation_id) to '${rmspp_datadir}/${f_species}' csv "
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
done < ${rm_datadir}/bien_ranges_species
echo -ne "\rDumping range model data by species: "$lastspecies"..."
source "${includesdir}/check_status.sh"

# Dump range model species attribute file, CSV with header
echoi $i -n "Exporting range model species attributes file..."
sql="\copy (SELECT species_nospace AS species, family, taxonomic_status, higher_plant_group, is_vasc, growth_form FROM ${SCH}.${TBL_RMS} ORDER BY species_nospace ) to '${rm_datadir}/${sdm_spp_outfile}' csv header"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

# 
# Send process completion message
#

source "${includesdir}/finish.sh"