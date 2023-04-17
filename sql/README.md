# Naming conventions for "range\_model\_data\_raw\_RUNDATE.sql" files

Run-specific sql files (i.e., with names beginning "range\_model\_data\_raw\_" include a year, month, day suffix before the ".sql" file extension. As of 2023, the suffix MUST be of the form yyyymmdd. E.g., "range\_model\_data\_raw\_20230411.sql". This is because the file name is constructed with run date as a parameter of format yyyymmdd. If format is incorrect, the script will fail.
