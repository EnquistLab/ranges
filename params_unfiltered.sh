#############################################################
# Parameters
#############################################################

# The SELECT clause of columns to return
# Includes all columns from the normal range model SELECT, plus all columns
# from the WHERE clause, plus a few more.
# Wrapping in HEREDOC to allow line endings without crashing psql command
SQL_SELECT=$(cat << HEREDOC

SELECT taxonobservation_id, 
observation_type, datasource, dataset, datasetkey,
fk_tnrs_id, verbatim_scientific_name, name_matched, name_matched_author,
matched_taxonomic_status, scrubbed_species_binomial, scrubbed_taxon_name_no_author, 
scrubbed_author, scrubbed_taxonomic_status AS taxonomic_status,
higher_plant_group, 
latitude, longitude, is_invalid_latlong, invalid_latlong_reason,
fk_gnrs_id, country, is_geovalid,
fk_cds_id, is_centroid, georef_protocol, 
nsr_id, is_location_cultivated, is_cultivated_observation, native_status, is_introduced,
event_date

HEREDOC
)

# No WHERE clause. All condition columns moved to SQL_SELECT
SQL_WHERE=""

# SQL record limit for testing with small batch of records
# Set to empty string to remove limit for production run 
LIMIT=""
LIMIT=1000

# Run date
# CRITICAL! This identifies a unique model run
# Also used to form names of run-specific postgres tables and data directory
# MUST be unix-friendly (no spaces, etc.)
# Preferred format: yyyymmdd, but not required. Can also add other suffix to uniquely
# identify a run
run="unfiltered"

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
wd=$basedir"/ranges"

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
