# ==========================================================================
# Purpose: Saves datasets as Parquet files for easy access
# Authors: Derek Kusmenko and Arusan Surendiran
# ==========================================================================

library(opendatatoronto)
library(tidyverse)
library(janitor)
library(lubridate)
library(arrow)
library(here)

package_id <- "7e876c24-177c-4605-9cef-e50dd74c617f"

# Identify resources for 2022-2025
bike_resources <- list_package_resources(package_id) %>%
  mutate(year = str_extract(name, "202[2-5]")) %>%
  filter(!is.na(year))

# Helper to standardize column types across inconsistent monthly files
fetch_standardized_bike_data <- function(resource_id) {
  raw_data_list <- get_resource(resource_id)

  map(raw_data_list, ~ .x %>%
    clean_names() %>%
    # Coerce IDs to character to prevent bind_rows type-mismatch errors
    mutate(across(any_of(c("bike_id", "start_station_id", "end_station_id")), as.character))) %>%
    bind_rows()
}

# Execute download and combine into a single raw dataframe
all_bike_raw <- map_df(bike_resources$id, fetch_standardized_bike_data)

# Handle 2025 (ISO/YMD) separately from 2022-2024 (MDY) to prevent year-swapping errors
bike_2025 <- all_bike_raw %>%
  filter(str_detect(start_time, "-")) %>%
  mutate(across(c(start_time, end_time), ymd_hms, .names = "dt_{.col}"))

bike_legacy <- all_bike_raw %>%
  filter(!str_detect(start_time, "-")) %>%
  mutate(across(c(start_time, end_time), mdy_hm, .names = "dt_{.col}"))

# Final Cleaning

bike_clean <- bind_rows(bike_2025, bike_legacy) %>%
  # Remove rows with unparseable dates or missing station names
  filter(
    !is.na(dt_start_time),
    start_station_name != "NULL",
    end_station_name != "NULL"
  ) %>%
  mutate(
    start_date = as_date(dt_start_time),
    year       = year(dt_start_time),
    month      = month(dt_start_time, label = TRUE),
    hour       = hour(dt_start_time)
  ) %>%
  # Remove potential duplicates from overlapping resource downloads
  distinct(trip_id, .keep_all = TRUE) %>%
  arrange(dt_start_time)

# File Export

# Save full multi-year dataset to Parquet for maximum compression and speed
# write_parquet(bike_clean, here("toronto_bike_share.parquet"))

# Filter for Beach BIA stations
beaches_ids <- c(
  "7692", "7317", "7318", "7365", "7427", "7315",
  "7695", "7364", "7314", "7316", "7428"
)

# Includes "7309", "7313", "8190" (left side of BIA)
# beaches_ids <- c("7309", "7313", "8190", "7314", "7427", "7695", "7428", "7365", 
#                  "7692", "7315", "7316", "7364", "7317", "7318")

beaches_trips <- bike_clean %>%
  filter(start_station_id %in% beaches_ids | end_station_id %in% beaches_ids) |>
  mutate(
    trip_direction = case_when(
      start_station_id %in% beaches_ids & end_station_id %in% beaches_ids ~ "Internal",
      start_station_id %in% beaches_ids ~ "Outbound",
      end_station_id %in% beaches_ids ~ "Inbound",
      TRUE ~ "Unknown"
    ))

output_file <- here("01-data", "clean", "beaches_bike_trips.parquet")
write_parquet(beaches_trips, output_file)

print(paste("Saved", nrow(beaches_trips), "beach-related trips"))