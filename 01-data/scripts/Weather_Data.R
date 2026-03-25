# Script: Toronto Weather Data Loading & Processing
# Project: The Beach BIA Analytics
# Authors: Derek Kusmenko & Arusan Surendiran
# Description: Fetches hourly historical climate data from Environment Canada
#              (Station 31688) and aggregates to daily summaries.


library(tidyverse)
library(janitor)
library(lubridate)
library(zoo)
library(arrow)
library(here)

stn_id <- 31688
years  <- 2022:2026

# Generate download tasks for completed months only
tasks <- expand_grid(year = years, month = 1:12) |>
  filter(make_date(year, month) <= today())

# Data

# Download and combine monthly weather CSVs
df_weather <- map2_dfr(tasks$year, tasks$month, function(y, m) {
  url <- paste0("https://climate.weather.gc.ca/climate_data/bulk_data_e.html?",
                "format=csv&stationID=", stn_id, "&Year=", y, "&Month=", m, 
                "&Day=1&timeframe=1&submit=Download+Data")
  
  read_csv(url, col_types = cols(.default = "c"), show_col_types = FALSE)
})

# Cleaning

climate_clean <- df_weather |>
  type_convert(guess_integer = TRUE) |>
  clean_names() |>
  mutate(
    date_time = as_datetime(date_time_lst),
    # Ensure numeric types for calculation
    across(c(temp_c, precip_amount_mm, rel_hum_percent, stn_press_k_pa), as.numeric)
  ) |>
  arrange(date_time) |>
  mutate(
    # Handle missing values
    precip_amount_mm = replace_na(precip_amount_mm, 0),
    temp_c           = na.approx(temp_c, na.rm = FALSE, rule = 2),
    rel_hum_percent  = na.approx(rel_hum_percent, na.rm = FALSE, rule = 2),
    # Fill pressure gaps with median
    stn_press_k_pa   = replace_na(stn_press_k_pa, median(stn_press_k_pa, na.rm = TRUE))
  )

# Daily Aggregation

climate_daily <- climate_clean |>
  mutate(date = as.Date(date_time)) |>
  group_by(date) |>
  summarise(
    temp_max = max(temp_c, na.rm = TRUE),
    temp_min = min(temp_c, na.rm = TRUE),
    temp_mean = mean(temp_c, na.rm = TRUE),
    total_precip_mm = sum(precip_amount_mm, na.rm = TRUE),
    is_precip = ifelse(total_precip_mm > 0, 1, 0),
    precip_hour_count = sum(precip_amount_mm > 0, na.rm = TRUE),
    .groups = "drop")


# File Export

# Save hourly data and daily summary as Parquet files

clean_path <- here("01-data", "clean")

write_parquet(climate_clean, file.path(clean_path, "toronto_weather_hourly_2022_2026.parquet"))
write_parquet(climate_daily, file.path(clean_path, "toronto_weather_daily.parquet"))
saveRDS(climate_daily, file.path(clean_path, "toronto_weather_daily.rds"))


