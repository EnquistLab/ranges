f_params="params_unfiltered_20230501.sh"  # Unfiltered range model data for Cory & Pep
#!/bin/bash

#########################################################################
# Extract BIEN data unfiltered
#
# One-off script to pull all vfoi rows to new table, including only 
# columns relevant to range model data and the fields used in the
# WHERE clause. For Cory and Pep study on the effects of different
# BIEN validations, standardizations and filters
#
# Notes:
#  1. All parameters set in params_unfiltered.sh
#  1. Range model data tables saved to schema "range_data"
#  2. Directories $rm_datadir and $rmspp_datadir must also exist (if savedata="t")
#  3. If savedata="t":
#		* Data exported to filesystem, to directories $rm_datadir (see params.sh)
#		* The above directory will be created if not already exist
#		* Observations for each species saved to separate files in subdir species/
#		* Unlike actual range model data, species attribute table and 
#         file are not produced, only a list of species binomials
#########################################################################

# Name of parameters file. 
# CRITICAL! This is the only parameter you need to set in this file.
f_params="params_unfiltered_20230501.sh"  # Unfiltered range model data for Cory & Pep
f_params="params_unfiltered.sh"  # Unfiltered range model data for Cory & Pep

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
	Save data to files:	$savedata
	Model data dir: 	$rm_datadir
	Species data dir: 	$rmspp_datadir
	Run code:		$run
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
echoi $i -n "Extracting unfiltered range model data to table ${TBL_RMD}..."
PGOPTIONS='--client-min-messages=warning' \
psql -U $USER -d $DB -q --set ON_ERROR_STOP=1 \
-v SCH="$SCH" -v SCH_RMD="$SCH_RMD" \
-v TBL_RMD="${TBL_RMD}" \
-v TBL_RMD_SSB_IDX="${TBL_RMD_SSB_IDX}" -v TBL_RMD_SNS_IDX="${TBL_RMD_SNS_IDX}" \
-v SQL_SELECT="${SQL_SELECT}" -v SQL_WHERE="${SQL_WHERE}" -v SQL_LIMIT="${SQL_LIMIT}" \
-f "${srcdir}/sql/range_model_data_raw.sql"
source "${includesdir}/check_status.sh"

if [ "$savedata" == "t" ]; then

	echoi $i -n "Dumping list of species to file..."
	sql="\copy (SELECT DISTINCT species_nospace FROM ${SCH_RMD}.${TBL_RMD} ORDER BY species_nospace) TO '${rm_datadir}/range_model_species' WITH (FORMAT CSV)"
	PGOPTIONS='--client-min-messages=warning' \
	psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
	source "${includesdir}/check_status.sh"

	# Dump range model data, one file per species, no header
	echoi $i -n "Dumping unfiltered range model data by species "
	while read SPECIES
	do
		#species_ns="${SPECIES// /_}"
		f_species="${SPECIES}.csv"
		echo -ne "\rDumping unfiltered range model data by species ${SPECIES}           "
		lastspecies=$SPECIES
		sql="\copy (SELECT * FROM ${SCH_RMD}.${TBL_RMD} WHERE species_nospace='${SPECIES}' ORDER BY taxonobservation_id) to '${rmspp_datadir}/${f_species}' csv header "
		PGOPTIONS='--client-min-messages=warning' \
		psql -U $USER -d $DB --set ON_ERROR_STOP=1 -q -c  "${sql}"
	done < ${rm_datadir}/range_model_species

	echo -ne "\rDumping unfiltered range model data by species "$lastspecies"..."
	source "${includesdir}/check_status.sh"
else
	echoi $i "[Generated Postgres tables only; data not saved to filesystem]"
fi

# 
# Send process completion message
#

source "${includesdir}/finish.sh"