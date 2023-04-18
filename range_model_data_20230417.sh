#!/bin/bash

#########################################################################
# Extract BIEN range model data
#
# Notes:
#  1. All parameters set in params_[RUNDATE].sh
#  1. Range model data tables saved to schema "range_data"
#  2. Schema "range_data" must already exist; it is not created by this script
#  3. Directories $rm_datadir and $rmspp_datadir must also exist (if savedata="t")
#  4. If savedata="t":
#		* Data exported to filesystem, to directories $rm_datadir
#		* The above directory will be created if not already exist
#		* Observations for each species saved to separate file in subdir species/
#		* Species attributes saved to single, separate file
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
# Load parameters file
#

source "params_20230417.sh"

if [ "$LIMIT" == "" ]; then
	LIMITCLAUSE=""
else
	LIMITCLAUSE=" LIMIT ${LIMIT} "
fi

# Range model metadata file
# Note: individual species data in separate files [Genus]_[species].csv
sdm_spp_outfile="${TBL_RMS}.csv"

# Load generic functions
source $includesdir"/${f_func}"	# Load functions file(s)



#
# Get command line parameters
# Can over-ride parameters loaded from file (above)
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
	Source schema:		$SCH
	Destination schema:	$SCH_RMD
	User:			$USER
	Raw data table:		$TBL_RMD
	Raw species table:	$TBL_RMS
	Save data to files:	$savedata
	Species file:		$sdm_spp_outfile
	Model data dir: 	$rm_datadir
	Species data dir: 	$rmspp_datadir
	Run date:		$rundate
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

# Set table-specific index name oparameters
TBL_RMD_SSB_IDX="${TBL_RMD}_scrubbed_species_binomial_idx"
TBL_RMD_SNS_IDX="${TBL_RMD}_species_nospace_idx"

# Extract table of raw data
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" \
-v TBL_RMD_SSB_IDX="${TBL_RMD_SSB_IDX}" -v TBL_RMD_SNS_IDX="${TBL_RMD_SNS_IDX}" \
-v SQL_WHERE="${SQL_WHERE}" -v LIMITCLAUSE="${LIMITCLAUSE}" \
-f "${srcdir}/sql/range_model_data_raw.sql"
source "${includesdir}/check_status.sh"

# Extract table of species and attributes
echoi $i -n "Extracting range model species to table ${TBL_RMS}..."
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" -v TBL_RMS="${TBL_RMS}" \
-f "${srcdir}/sql/range_model_species.sql"
source "${includesdir}/check_status.sh"

if [ "$savedata" == "t" ]; then
	echoi $i -n "Creating range model data directories (if not exist)..."
	mkdir -p "${rmspp_datadir}"
	source "${includesdir}/check_status.sh"

	echoi $i -n "Dumping range model species to file..."
	sql="\copy (SELECT DISTINCT species_nospace FROM ${SCH_RMD}.${TBL_RMD} ORDER BY species_nospace) TO '${rm_datadir}/bien_ranges_species' WITH (FORMAT CSV)"
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
	sql="\copy (SELECT taxonobservation_id, species_nospace AS species, latitude, longitude FROM ${SCH_RMD}.${TBL_RMD} WHERE species_nospace='${SPECIES}' ORDER BY taxonobservation_id) to '${rmspp_datadir}/${f_species}' csv "
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
	done < ${rm_datadir}/bien_ranges_species
	echo -ne "\rDumping range model data by species: "$lastspecies"..."
	source "${includesdir}/check_status.sh"

	# Dump range model species attribute file, CSV with header
	echoi $i -n "Exporting range model species attributes file..."
	sql="\copy (SELECT species_nospace AS species, family, taxonomic_status, higher_plant_group, is_vasc, growth_form FROM ${SCH_RMD}.${TBL_RMS} ORDER BY species_nospace ) to '${rm_datadir}/${sdm_spp_outfile}' csv header"
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