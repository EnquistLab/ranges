#############################################################
# Parameters
# For main range model run on 2023-05-24
#############################################################

# Run date
# CRITICAL! This identifies a unique model run
# Also used to form names of run-specific postgres tables and data directory
# MUST be unix-friendly (no spaces, etc.)
# Preferred format: yyyymmdd
# Add suffix if a later part of a multiple-part run: yyyymmdd_suffix
# E.g., "20230405_missing_spp"
run="20241210"

# SQL record limit for testing with small batch of records
# Set to empty string to remove limit for production run 
LIMIT=""
LIMIT=100

# Save data to filesystem (t|f)
# if "f" then just produces postgres tables
savedata="t"

########################################
# Supplemental run parameters
#######################################

# Is this a missing species run? (t|f)
# False (f): a main run with is_introduced=1
# True (t): a supplemental missing species run with is_introduce=NULL
missing_spp_run="f"

# Previous run code
# CRITICAL if $missing_spp_run=="t"
# Ignored if $missing_spp_run=="f"
# Used to form name of previous run species table, which 
# is used for checking and removing shared species
prev_run=""

########################################
# WHERE clause parameters
#######################################

# The SELECT clause of columns to return
# Wrapping in HEREDOC enables multi-line parameter without 
# crashing psql command
SQL_SELECT=$(cat << HEREDOC

SELECT taxonobservation_id, 
scrubbed_species_binomial, latitude, longitude, 
scrubbed_taxonomic_status AS taxonomic_status, higher_plant_group, 
country, native_status, is_introduced, 
observation_type, event_date

HEREDOC
)

# The main WHERE clause used to filter range model for this run
# Do NOT include the filter on 'is_introduced'; that goes in separate
# parameter SQL_WHERE_INTRODUCED, below.
SQL_WHERE_MAIN=$(cat << HEREDOC

WHERE scrubbed_species_binomial IS NOT NULL 
AND higher_plant_group IN ('bryophytes', 'ferns and allies','flowering plants','gymnosperms (conifers)', 'gymnosperms (non-conifer)') 
AND is_invalid_latlong=0 
AND is_geovalid = 1 
AND (georef_protocol is NULL OR georef_protocol<>'county_centroid') 
AND (is_centroid IS NULL OR is_centroid=0) 
AND is_location_cultivated IS NULL 
AND (is_cultivated_observation = 0 OR is_cultivated_observation IS NULL) 
AND observation_type IN ('plot','specimen','literature','checklist') 
AND ( EXTRACT(YEAR FROM event_date)>=1950 OR event_date IS NULL )

HEREDOC
)

# Just the "is_introduced" component of the WHERE clause
# Begin with 'AND ' instead of 'WHERE' as the filter, if used, 
# will be  added to the main WHERE clause (above). 
SQL_WHERE_INTRODUCED=$(cat << HEREDOC

AND is_introduced=0

HEREDOC
)

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
includesdir=$basedir"/submodules/includes"

# Name of shared functions file
f_func="functions.sh"

# Process name for email notifications
pname="BIEN range model data extract on ${run}"

# Default email address for notifications (start, finish, error)
# Used if you supply command line parameter -m 
email="bboyle@email.arizona.edu"
email="ojalaquellueva@gmail.com"

#############################################################
# The remaining parameters shouldn't change unless you 
# fundamentally restructure the application
#############################################################

# Working directory 
wd=$basedir"/ranges_data"

# Source code base directory (this one containing this script)
srcdir=$wd"/src"

# input data directory 
datadir=$wd"/data"

# range model data base directory 
rm_datadir=$datadir"/rm_data_${run}"

# range model species data directory 
rmspp_datadir=$rm_datadir"/species"

#
# Table and file names
#

# Range model data table
TBL_RMD="range_model_data_raw_${run}"

# Range model species table
TBL_RMS="range_model_species_${run}"

# Range model data statistics table
TBL_RMDS="range_model_data_stats_${run}"

# Range model species attributes file
# Note: individual species data in separate files [Genus]_[species].csv
rms_outfile="range_model_species_attributes_${run}.csv"

