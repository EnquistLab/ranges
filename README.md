# BIEN SDM Data export and validation

## Overview

The scripts in this repository export odata from the BIEN database for species distribution modeling.  

For creation of the BIEN ranges database and import of complete SDM output, see:  `https://github.com/EnquistLab/bien-range` 

## Application directory structure

```
ranges/
|-- data/ [range model data exported to here]
    |-- rm_dat   a_20230418/
        |-- bien_ranges_species.csv
        |-- bien_range_model_data.csv
        |-- species/
            |-- Aa_achalensis.csv
            |-- Aa_peruviana.csv
            |-- [etc.]
|-- docs/ 
|-- src/ [git repo; all application code here. Main scripts at top level]
    |-- params.sh [parameters file]
    |-- range_model_data.sh [main data export script in bash]
    |-- README.md
    |-- sql/ [sql scripts called by main shell scripts in src/]
        |-- multistatus_species.sql
        |-- range_model_data_raw.sql
        |-- range_model_species.sql
        |-- README.md
    |-- validations/ [standalone validation scripts, mostly SQL]
```

## Usage

All tasks are performed by main shell scripts in base directory (this one). SQL is either executed directly in main script, or sourced as SQL files in subdirectory sql/.


### Export SDM species occurrence input data from BIEN analytical database
* After setting parameters, execute the main shell script in src/:

```
./range_model_data.sh [-m]
```

**Notes:**  
* Uses parameters in params.sh. Check all carefully!  
* Note especially $rundate: uniquely identifies a complete set of data for a unique model run. Format yyyymmdd.  
* After extracting data for final production run of range models, commit & tag all code and push to GitHub  

### [minor] Import SDM species to BIEN analytical database
* A one-time operation to import list of species to the BIEN database and add additional species traits. Unlikely to be used again.

```
./load_sdm_species.sh 
```


