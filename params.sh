#
# Parameters
#

# The WHERE clause used to filter range model for this run
# Wrapping in HEREDOC for easier reading without crashing psql 
# command due to line endings
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

# SQL record limit for testing with small batch of records
# Set to empty string to remove limit for production run 
LIMIT=100
LIMIT=""

# Run date
# CRITICAL! This identifies a unique model run
# Also used to form names of run-specific postgres tables and data directory
# MUST be unix-friendly (no spaces, etc.)
# Preferred format: yyyymmdd
rundate="20230418"

# Save data to filesystem (t|f)
# if "f" then just produces postgres tables
savedata="t"

# Database parameters
# SCH is the schema of the main BIEN analytical DB (source schema)
# SCH_RMD is range model data schema (target schema, where data tables generated)
DB="vegbien"
USER="bien"
SCH="analytical_db"
SCH_RMD="range_data"

# Base directory
# Full path to parent directory of module base directory (i.e., parent of ranges/)
# CRITICAL! All other directories are set relative to this one
basedir="/home/boyle/bien"

# Directory of wherever shared functions & utilities files are kept
includesdir=$basedir"/includes/sh"

# Name of shared functions file
f_func="functions.sh"

# Process name for email notifications
pname="BIEN range model data extract on ${rundate}"

# Default email address for notifications (start, finish, error)
# Used if you supply command line parameter -m 
email="bboyle@email.arizona.edu"
email="ojalaquellueva@gmail.com"

#
# The remaining parameters shouldn't change unless you 
# fundamentally restructure the application
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
