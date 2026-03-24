# 01-Data Directory

This directory contains the data used for The Beach BIA Project. We have organized it so that original downloads are kept separate from the clean files used for analysis.

### Directory Structure

* **`scripts/`**: Contains R scripts used to fetch data from online sources (Open Data Toronto, Toronto Bike Share, and Toronto Climate) and perform initial cleaning.
* **`raw/`**: Stores original data files (CSV) as they were downloaded from the source (iNaturalist).
* **`clean/`**: Contains the final processed datasets saved in Parquet and RDS formats for analysis.

### Cleaned Data Files

_beach_inaturalist_: A record of natural organism observations in the Beaches area. Includes locations (lat/lon) and dates of observation.

_beach_water_quality_: Daily E. coli levels for Kew-Balmy and Woodbine Beaches. Includes a "closure status" to show when it was unsafe to swim.

_beaches_bike_trips_: Bike share data specifically filtered for trips starting or ending at stations near the Beach BIA.

_toronto_bike_stations_: A list of all Toronto bike stations, including their unique IDs and locations.

_toronto_weather_daily_: Daily summaries of Toronto weather (high/low temps and total rain) from 2022 to the present.

_toronto_weather_hourly_2022_2026_: Detailed hourly weather data
