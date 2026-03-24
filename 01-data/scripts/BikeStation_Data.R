# ==========================================================================
# Project: The Beach BIA
# Script: Station Data Retrieval
# 
# Data Source: Toronto Bike Share General Bikeshare Feed Specification (GBFS)
# Data Retrieval: Live API pull from the official station_information endpoint.
# 
# Objective: 
# This script collects the metadata for all active TorontoBike Share stations 
# (ID, Name, Capacity, and Geocoordinates).
# ==========================================================================


# Load Libraries
library(arrow)
library(jsonlite)
library(dplyr)

# Define the Toronto Bike Share API URL (Station Information)

# This is the official feed for station names, IDs, lat/long, and capacity
url <- "https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_information"

# Download and Flatten the JSON
# The data is nested under "data$stations"

raw_json <- fromJSON(url)
stations_df <- raw_json$data$stations

# Clean up the data types

stations_clean <- stations_df %>%
  select(-rental_uris) |>
  mutate(
    lat = as.numeric(lat),
    lon = as.numeric(lon),
    capacity = as.integer(capacity)
  )

# Save as Parquet in your project folder

clean_path <- here("01-data", "clean")
write_parquet(stations_clean, file.path(clean_path, "toronto_bike_stations.parquet"))

