#!/bin/bash

#########################################################################
# Extract BIEN range model data
#
# This is the main range model data extraction script. All parameters are set in
# the single parameters file, which has a date suffix. Once a script has
# been used for a production extract of range model data (and the actual models
# produced, served publicly from BIEN applications and/or used in publications),
# all changes should be committed, pushed to GitHub and a tag (version number) 
# assigned and also pushed. Rather than semantic versioning, the most accurate
# tag is $run (yyyymmdd), as assigned in the params file. Given this 
# information, the version numbers of the BIEN DB and all validation applications 
# can be reconstructed.
#
# Notes:
#  1. All parameters set in params.sh
#  1. Range model data tables saved to schema "range_data"
#  2. Directories $rm_datadir and $rmspp_datadir must also exist (if savedata="t")
#  3. If savedata="t":
#		* Data exported to filesystem, to directories $rm_datadir (see params.sh)
#		* The above directory will be created if not already exist
#		* Observations for each species saved to separate files in subdir species/
#		* Species attributes saved to separate file
#########################################################################

# Name of parameters file. 
# CRITICAL! This is the only parameter you need to set in this file.
f_params="params_20230524.sh"  # BIEN 4.2.6 range model data production run 2023-05-24

# Load parameters
source "$f_params"  

if [ "$LIMIT" == "" ]; then
	SQL_LIMIT=""
else
	SQL_LIMIT=" LIMIT ${LIMIT} "
fi

# Load generic functions
source $includesdir"/${f_func}"	# Load functions file(s)

#
# Get command line parameters
# Parameters set on the command will over-ride those set in the params 
# file (see above)
#  

# Set defaults
i="true"						# Interactive mode on by default
e="true"						# Echo on by default
verbose="false"					# Minimal progress output
m="false"

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
# Confirm operation
#

# Set custom display values for confirmation message
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

	Run process '$pname' with the following parameters: 
	
	Database:		$DB
	Source schema:		$SCH
	Destination schema:	$SCH_RMD
	User:			$USER
	Raw data table:		$TBL_RMD
	Raw species table:	$TBL_RMS
	Save data to files:	$savedata
	Species file:		$rms_outfile
	Model data dir: 	$rm_datadir
	Species data dir: 	$rmspp_datadir
	Run date:		$run
	Run type:		$runtype
	Record limit:		$limit_disp
	Send notifications?:	$m
EOF
	)"		
	confirm "$msg_conf"
fi

# Start timer & get process ID
start=`date +%s%N`; prev=$start
pid=$$

# Send notification email if this option set
if [ "$m" == "true" ]; then
	source "${includesdir}/mail_process_start.sh"
fi

# 
# Main
#

echoi $i " "
echoi $i "------ Begin process '$pname' -----"
echoi $i " "

echoi $i -n "Creating schema ${SCH_RMD} if not exists..."
sql="CREATE SCHEMA IF NOT EXISTS ${SCH_RMD}"
PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
source "${includesdir}/check_status.sh"

if [ "$savedata" == "t" ]; then
	echoi $i -n "Creating range model data directories..."
	
	if [ -d "${rm_datadir}" ]; then
		echo "ERROR: directory ${rm_datadir} already exists! Delete before running this script."
		exit 1
	else
		mkdir -p "${rmspp_datadir}"
		source "${includesdir}/check_status.sh"
	fi
fi 

# Extract raw observations
echoi $i -n "Extracting range model data to table ${TBL_RMD}..."
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" \
-v TBL_RMD_SSB_IDX="${TBL_RMD_SSB_IDX}" -v TBL_RMD_SNS_IDX="${TBL_RMD_SNS_IDX}" \
-v SQL_SELECT="${SQL_SELECT}" -v SQL_WHERE="${SQL_WHERE}" -v SQL_LIMIT="${SQL_LIMIT}" \
-f "${srcdir}/sql/range_model_data_raw.sql"
source "${includesdir}/check_status.sh"

# Delete observations where taxonomic status unresolved AND species has >1 status
echoi $i -n "Deleting observations where taxonomic_status=\"Unresolved\" and species has >1 taxonomic status..."
# Extract table of raw data
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" -v TBL_RMS="${TBL_RMS}" -v TBL_RMDS="${TBL_RMDS}" \
-f "${srcdir}/sql/multistatus_species.sql"
source "${includesdir}/check_status.sh"

# Extract table of species and attributes
echoi $i -n "Extracting range model species to table ${TBL_RMS}..."
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" -v TBL_RMS="${TBL_RMS}"  -v TBL_RMDS="${TBL_RMDS}" \
-f "${srcdir}/sql/range_model_species.sql"
source "${includesdir}/check_status.sh"

if [ "$savedata" == "t" ]; then

	echoi $i -n "Dumping range model species to file..."
	sql="\copy (SELECT DISTINCT species_nospace FROM ${SCH_RMD}.${TBL_RMD} ORDER BY species_nospace) TO '${rm_datadir}/range_model_species' WITH (FORMAT CSV)"
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
	source "${includesdir}/check_status.sh"

	# Dump range model data, one file per species, no header
	echoi $i -n "Dumping range model data by species: "
	while read SPECIES
	do
		#species_ns="${SPECIES// /_}"
		f_species="${SPECIES}.csv"
		echo -ne "\rDumping range model data by species: ${SPECIES}            "
		lastspecies=$SPECIES
		sql="\copy (SELECT taxonobservation_id, species_nospace AS species, latitude, longitude FROM ${SCH_RMD}.${TBL_RMD} WHERE species_nospace='${SPECIES}' ORDER BY taxonobservation_id) to '${rmspp_datadir}/${f_species}' csv header"
		PGOPTIONS='--client-min-messages=warning' \
		psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
	done < ${rm_datadir}/range_model_species

	echo -ne "\rDumping range model data by species: "$lastspecies"..."
	source "${includesdir}/check_status.sh"

	# Dump range model species attribute file, CSV with header
	echoi $i -n "Exporting range model species attributes file..."
	sql="\copy (SELECT species_nospace AS species, family, taxonomic_status, higher_plant_group, is_vasc, growth_form FROM ${SCH_RMD}.${TBL_RMS} ORDER BY species_nospace ) to '${rm_datadir}/${rms_outfile}' csv header"
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c "${sql}"
	source "${includesdir}/check_status.sh"
else
	echoi $i "[Generated Postgres tables only; data not saved to filesystem]"
fi

# 
# Send process completion message
#

source "${includesdir}/finish.sh"