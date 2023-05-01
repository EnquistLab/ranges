# BIEN SDM Data export and validation

## Overview

The scripts in this repository export odata from the BIEN database for species distribution modeling.  

For creation of the BIEN ranges database and import of complete SDM output, see:  `https://github.com/EnquistLab/bien-range` 

## Application directory structure

```
ranges/
|__ data/ [range model data exported to here]
|   |__ rm_data_20230418/
|   |__ range_model_species_attributes.csv [list of spp & attributes]
|        |__ species/ [individual species data, one file per species]
|            |__ Aa_achalensis.csv
|            |__ Aa_peruviana.csv
|            |__ [etc.]
|__ docs/ [Miscellaneous documentation here]
|__ src/ [Application code here & git repo]
    |__ params_20230418.sh [parameters file; suffix uniquely identifies run]
    |__ range_model_data.sh [Range model data export main script]
    |__ README.md
    |__ sql/ [SQL scripts sourced by main scripts in src/]
    |   |__ multistatus_species.sql
    |   |__ range_model_data_raw.sql
    |   |__ range_model_species.sql
    |   |__ README.md
    |__ validations/ [standalone validation scripts]
```

## Usage

All tasks are performed by main shell scripts in base directory (this one). SQL is either executed directly in main script, or sourced as SQL files in subdirectory sql/.


### Export SDM species occurrence input data from BIEN analytical database
* Main script ranges/src/range_model_data.sh, call all others.
* Before running:
   * Set correct name of parameters script (e.g., "source "params_20230418.sh" 
   * 

```
./range_model_data.sh [-m]
```

**Notes:**  
* Uses parameters in params.sh. Check all carefully!  
* Note especially $run: uniquely identifies the dataset used for a unique model run. Recommended format yyyymmdd; may also include additional suffix.
* After extracting data for final production run of range models, commit & tag all code and push to GitHub  

### [minor] Import SDM species to BIEN analytical database
* A one-time operation to import list of species to the BIEN database and add additional species traits. Unlikely to be used again.

```
./load_sdm_species.sh 
```


