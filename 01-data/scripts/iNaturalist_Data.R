# Data Source: iNaturalist Biodiversity Observations (The Beach, Toronto)

# Using an account, export from https://www.inaturalist.org/observations/export

# Data Retrieval: Data was manually exported from the iNaturalist platform using
# the web-based export tool. The dataset includes all observations with any 
# quality grade or identification status recorded since January 1, 2022.

# Geographic Parameters: The search was constrained to a custom bounding box 
# covering the Toronto Beaches neighborhood:
  
# Southwest Corner: 43.65924, -79.32948
# Northeast Corner: 43.68081, -79.28002


# Columns:
#   id: Unique, sequential identifier for the observation
# uuid: Universally unique identifier for the observation. 
# observed_on_string: Date/time as entered by the observer
# observed_on: Normalized date of observation
# time_observed_at: Normalized datetime of observation
# user_id: Unique, sequential identifier for the observer
# created_at: Datetime observation was created
# quality_grade: Quality grade of this observation.
# latitude: Publicly visible latitude from the observation location
# longitude: Publicly visible longitude from the observation location
# private_latitude: Private latitude, set if observation private or obscured
# private_longitude: Private longitude, set if observation private or obscured


# Format Conversion: To optimize the data files, the raw CSV file was converted
# to Parquet format.

library(arrow)
library(dplyr)
library(lubridate)

# Load the raw CSV downloaded from iNaturalist

raw_path <- "01-data/inaturalist-observations.csv"
df_raw <- read.csv(raw_path, stringsAsFactors = FALSE)

# Clean and Format for Analysis

df_cleaned <- df_raw %>%
  mutate(
    observed_on = as.Date(observed_on),
    time_observed_at = ymd_hms(time_observed_at),
    created_at = ymd_hms(created_at)
  )

# Save as Parquet

clean_path <- here("01-data", "clean")
write_parquet(df_cleaned, file.path(clean_path, "beach_inaturalist.parquet"))






