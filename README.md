# BIEN SDM Data export and validation

## Overview

The scripts in this repository perform the following actions:  

* Export of species distribution model data from the BIEN database.  
* Import of related SDM output such as species lists  

For creation of the BIEN ranges database and import of complete SDM output, see:  `https://github.com/EnquistLab/bien-range` 

Also see the main BIEN DB repo for legacy versions of range model export code (in directory `query_adb`): `https://github.com/EnquistLab/bien`


## Usage

All tasks are performed by main shell scripts in base directory (this one). SQL is either executed directly in main script, or sourced as SQL files in subdirectory sql/.

#### 1. Import SDM species to BIEN analytical database

```
./load_sdm_species.sh 
```

#### 2. Export SDM species occurrence input data from BIEN analytical database

```
./range_model_data_[RUNDATE].sh 
```

