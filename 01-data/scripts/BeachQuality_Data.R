# ==========================================================================
# Project: The Beach BIA
# Script: Beach Water Quality (E. coli) Data Retrieval and Cleaning
# 
# Data Source: City of Toronto Open Data Portal (Beach Water Quality dataset)
# Package ID: 92b0de8f-1ada-44a7-84cf-adc04868e990
# 
# Objective:
# This script retrieves historical E. coli monitoring data for Kew-Balmy 
# and Woodbine Beaches. The raw data is filtered for observations from 2022 
# onwards, cleaned, and aggregated into daily averages to account for multiple 
# test sites per beach. 
#
# A closure status is derived based on the Toronto Public Health threshold 
# (> 100 E. coli per 100ml of water).
# ==========================================================================


package <- show_package("92b0de8f-1ada-44a7-84cf-adc04868e990")
resources <- list_package_resources("92b0de8f-1ada-44a7-84cf-adc04868e990")
beach_ecoli_data <- get_resource("fa96223e-ccf8-4c0a-817b-6f5039311287")
kewbeach_ecoli_data <- beach_ecoli_data |> filter(beachName == "Kew Balmy Beach")
woodbine_ecoli_data <- beach_ecoli_data |> filter(beachName == "Woodbine Beaches")

kew_ecoli_cleaned <- kewbeach_ecoli_data |>
  mutate(
    Date = as.Date(collectionDate),
    Year = year(Date),
    Month = month(Date, label = TRUE)
  ) |>
  filter(Year >= 2022) |>
  # Handle missing values and group by day to average the different test sites
  group_by(Date, Year, Month) |>
  summarise(Daily_Avg_Ecoli = mean(eColi, na.rm = TRUE), .groups = "drop")

woodbine_ecoli_cleaned <- woodbine_ecoli_data |>
  mutate(
    Date = as.Date(collectionDate),
    Year = year(Date),
    Month = month(Date, label = TRUE)
  ) |>
  filter(Year >= 2022) |>
  # Handle missing values and group by day to average the different test sites
  group_by(Date, Year, Month) |>
  summarise(Daily_Avg_Ecoli = mean(eColi, na.rm = TRUE), .groups = "drop")


beach_status_full <- full_join(
  kew_ecoli_cleaned |> select(Date, ecoli_kew = Daily_Avg_Ecoli),
  woodbine_ecoli_cleaned |> select(Date, ecoli_woodbine = Daily_Avg_Ecoli),
  by = "Date"
) |>
  mutate(
    closed_kew = !is.na(ecoli_kew) & ecoli_kew > 100,
    closed_woodbine = !is.na(ecoli_woodbine) & ecoli_woodbine > 100,
    closure_status = case_when(
      closed_kew & closed_woodbine ~ "Both Closed (Red)",
      closed_kew ~ "Kew Only (Orange)",
      closed_woodbine ~ "Woodbine Only (Yellow)",
      (!is.na(ecoli_kew) | !is.na(ecoli_woodbine)) ~ "All Beaches Open",
      TRUE ~ "No Testing"
    )
  )

output_file <- "01-data/beach_water_quality.parquet"
write_parquet(beach_status_full, output_file)