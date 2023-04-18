#
# Parameters
#

# The WHERE clause this range model run
# Use of HEREDOC method enables multi-line format for easier reading while also
# preventing line endings from crashing psql command
SQL_WHERE=$(cat << HEREDOC

WHERE scrubbed_species_binomial IS NOT NULL 
AND higher_plant_group IN ('bryophytes', 'ferns and allies','flowering plants','gymnosperms (conifers)', 'gymnosperms (non-conifer)') 
AND is_invalid_latlong=0 
AND is_geovalid = 1 
AND (georef_protocol is NULL OR georef_protocol<>'county_centroid') 
AND (is_centroid IS NULL OR is_centroid=0) 
AND is_location_cultivated IS NULL 
AND (is_cultivated_observation = 0 OR is_cultivated_observation IS NULL) 
AND is_introduced=0 
AND observation_type IN ('plot','specimen','literature','checklist') 
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL )

HEREDOC
)

# LIMIT clause for testing only
# Set to empty string for production run 
LIMIT=""
LIMIT=100

# Run date
# CRITICAL! Used to form names of run-specific directory
# MUST be of format yyyymmdd
rundate="20230417"

# Save data to filesystem (t|f)
# if t then just produces postgres tables
savedata="t"

# Database params
# SCH is main BIEN DB schema (source schema)
# SCH_RMD is range model data schema (destination schema, where data tables generated)
DB="vegbien"
SCH="analytical_db"
SCH_RMD="range_data"
USER="bien"

# Range model data table
TBL_RMD="range_model_data_raw_${rundate}"

# Range model species table
TBL_RMS="range_model_species_${rundate}"

# Base directory
# Full path to parent directory of ranges/ 
# CRITICAL! All other directories are relative to this one
basedir="/home/boyle/bien"

# Directory of shared functions & utilities files
includesdir=$basedir"/includes/sh"

# Name of shared functions file
f_func="functions.sh"

# Process name for email notifications
pname="BIEN range model data extract on ${rundate}"

# Email address for notifications
# You must supply command line parameter -m to use this
email="bboyle@email.arizona.edu"

#
# The remaining parameters won't change unless you fundamentally 
# restructure the application
#

# Working directory 
wd=$basedir"/ranges"

# Source code base directory (this one containing this script)
srcdir=$wd"/src"

# input data directory 
datadir=$wd"/data"

# range model data base directory 
rm_datadir=$datadir"/rm_data_${rundate}"

# range model species data directory 
rmspp_datadir=$rm_datadir"/species"

