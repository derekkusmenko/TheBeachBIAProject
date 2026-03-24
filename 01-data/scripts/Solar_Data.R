# ==============================================================================
# Title: Toronto Solar Data Extraction 
# Description: This script calculates daily solar milestones including sunrise, 
#              sunset, and twilight durations for the Toronto area.
# ==============================================================================

# Load necessary libraries
# install.packages(c("suncalc", "dplyr", "arrow")) # Uncomment if not installed
library(suncalc)
library(dplyr)
library(arrow)

# Define Parameters
target_lat <- 43.66
target_lon <- -79.30
target_tz  <- "America/Toronto"
date_range <- seq(as.Date("2022-01-01"), as.Date("2025-12-31"), by = "day")

# Fetch and Process Sun Data
sun_data <- getSunlightTimes(
  data = data.frame(date = date_range, lat = target_lat, lon = target_lon), 
  keep = c("dawn", "sunrise", "sunset", "dusk"), 
  tz = target_tz
) %>%
  mutate(
    date = as.Date(date),
    # Duration of the sun actually being above the horizon
    daylight_hours = as.numeric(difftime(sunset, sunrise, units = "hours")),
    # Duration of usable light including civil twilight
    usable_light_hours = as.numeric(difftime(dusk, dawn, units = "hours")),
    # The period between sunset and dusk (Evening Civil Twilight)
    evening_twilight_hours = as.numeric(difftime(dusk, sunset, units = "hours"))
  )


# Export to Parquet

clean_path <- here("01-data", "clean")
write_parquet(sun_data, file.path(clean_path, "toronto_solar_data.parquet"))

# Confirmation
cat("Success! File saved as 'toronto_solar_data.parquet'.\n")
print(head(sun_data))
