01-Data Directory

This directory contains the data used for The Beach BIA Project. It follows a structure to separate raw source files from processed analytical datasets.

Directory Structure

scripts/: Contains R scripts used to fetch data from online sources (Open Data Toronto, Toronto Bike Share, and Toronto Climate) and perform initial cleaning.

raw/: Stores original data files (CSV) as they were downloaded from the source (iNaturalist).

clean/: Contains the final processed datasets saved in Parquet and RDS formats for analysis.
