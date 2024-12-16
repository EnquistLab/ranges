#!/bin/bash

#########################################################################
# Extract BIEN range model data - missing species supplemental run
#
# BIEN range model data extraction script. All parameters are set in
# the single parameters file, which has a date suffix. Once a script has
# been used for a production extract of range model data (and the actual models
# produced, served publicly from BIEN applications and/or used in publications),
# all changes should be committed, pushed to GitHub and a tag (version number) 
# assigned and also pushed. 
#
# Each run must be assigned a unique code, using the start date of the 
# run, in the format yyyymmdd. For a supplemental runs to extract additional
# species missed in first (main) run, the format is "[yyyymmdd]_missing_spp".
# After the run, archive the main script and parameters file by saving a 
# copy of each file, with the run code inserted as a suffix between the file
# basename and the ".sh" extension.  
#
# Note on missing species supplemental runs
# 
# Missing species (supplemental) runs supplement main range model data 
# run by extracting data for species missed due to 
# strict filtering of non-native observations (i.e., "is_introduced=0").
# This version includes only species not present in the first run which
# have one or more values of is_introduced=NULL (observations with 
# is_introduced=1 are never included). Flag is_introduced can be NULL 
# when either (a) the species does not appear in any NSR checklists
# (in which case, native_status=NULL) or (b) there is no checklist for 
# the region of observation (in which case, native_status="UNK" and 
# native_status_reason="Status unknown, no checklists for region of observation". 
# May also include observations of species with a subset of values with 
# is_introduced=NULL and the remainder with is_introduced=1. 
#
# Notes:
#  1. All parameters set in params_[run].sh
#  1. Range model data postgres tables saved to schema "range_data"
#  2. Directories $rm_datadir and $rmspp_datadir must also exist (if savedata="t")
#  3. If savedata="t":
#		* Data exported to filesystem, to directories $rm_datadir (see params.sh)
#		* The above directory will be created if not already exist
#		* Observations for each species saved to separate files in subdir species/
#		* Species attributes saved to separate file
#########################################################################

# Name of parameters file. 
# CRITICAL! This is the only parameter you need to set in this file.
f_params="params_20241210.sh"  
f_params="params_20241210_missing_spp.sh"  

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

if [ "$missing_spp_run" == "t" ]; then
	prev_run_disp="$prev_run"
	prev_run_spp_tbl_disp="$TBL_RMS_PREV"
else
	prev_run_disp="[n/a]"
	prev_run_spp_tbl_disp="[n/a]"
fi


if [[ "$i" = "true" && -z ${master+x} ]]; then 

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Run process '$pname' with the following parameters: 
	
	Run code:		$run
	Prev. run:		$prev_run_disp
	Database:		$DB
	Source schema:		$SCH
	Destination schema:	$SCH_RMD
	User:			$USER
	Raw data table:		$TBL_RMD
	Raw species table:	$TBL_RMS
	Prev species table:	$prev_run_spp_tbl_disp
	Save data to files:	$savedata
	Species file:		$rms_outfile
	Model data dir: 	$rm_datadir
	Species data dir: 	$rmspp_datadir
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
-v SQL_SELECT="${SQL_SELECT}" \
-v SQL_WHERE_MAIN="${SQL_WHERE_MAIN}" \
-v SQL_WHERE_INTRODUCED="${SQL_WHERE_INTRODUCED}" \
-v SQL_LIMIT="${SQL_LIMIT}" \
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

# Delete species & data for species shared with previous model run
# These queries for supplemental run only
if [ "$missing_spp_run" == "t" ]; then
	echoi $i -n "Creating table \"bien_spp_native_status\"..."
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
	-v SCH_RMD="$SCH_RMD" -v SCH_ADB="$SCH" \
	-v SQL_WHERE_MAIN="${SQL_WHERE_MAIN}" \
	-v SQL_LIMIT="${SQL_LIMIT}" \
	-v TBL_SPP_RUN1="${TBL_RMS_PREV}" \
	-f "${srcdir}/sql/create_bien_spp_native_status.sql"
	source "${includesdir}/check_status.sh"

	echoi $i -n "Deleting species shared with previous run..."
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
	-v SCH_RMD="$SCH_RMD" \
	-v TBL_SPP_RUN1="${TBL_RMS_PREV}" \
	-v TBL_SPP_RUN2="${TBL_RMS}" \
	-v TBL_DATA_RUN2="${TBL_RMD}" \
	-v TBL_STATS_RUN2="${TBL_RMDS}" \
	-f "${srcdir}/sql/delete_shared_species.sql"
	source "${includesdir}/check_status.sh"

	echoi $i -n "Deleting NSR species & keeping species with unknown native status only..."
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
	-v SCH_RMD="$SCH_RMD" \
	-v TBL_SPP_RUN2="${TBL_RMS}" \
	-v TBL_DATA_RUN2="${TBL_RMD}" \
	-v TBL_STATS_RUN2="${TBL_RMDS}" \
	-f "${srcdir}/sql/delete_nsr_species.sql"
	source "${includesdir}/check_status.sh"
fi

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