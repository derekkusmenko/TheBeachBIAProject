# The Beach BIA Project

This project, led by Derek Kusmenko and Arusan Surendiran, focuses on understanding human movement patterns within the Beaches Business Improvement Area (BIA) in Toronto. In collaboration with Dr. Johanna Carlo, we collect various datasets from the City of Toronto’s Open Data Portal, including transit delays, bike-share ridership, and traffic patterns within The Beach BIA.


## 📂 Repository Structure

The project follows a numbered workflow to ensure reproducibility and logical data flow:

| Directory | Description |
| :--- | :--- |
| **`01-data/`** | **Primary Data Pipeline.** Contains `scripts/` for fetching data, `raw/` for original files, and `clean/` for analysis-ready `.parquet` and `.rds` files. |
| **`01_Data/`** | Secondary data storage, containing CSV exports and specific bike/climate datasets. |
| **`02_Exploratory_Data_Analysis/`** | Initial data cleaning and visual exploration (EDA). Focuses on joining 311 data, tickets, and movement patterns. |
| **`03_BikeShare_Analysis/`** | Specialized deep-dives into Toronto Bike Share usage for the Beach BIA, including dwell time modeling, profile clustering, and heatmaps. |
| **`04_ProgressReport/`** | Documented project milestones and official progress reports for the MSc Statistics program. |
| **`05_Presentation/`** | Presentation materials and a folder of key plots. |
| **`06-BikeShare/`** | Geographic and spatial analysis components, specifically station-level mapping and spatial functions. |
| **`07_ExplanatoryModelling/`** | Contains Bayesian hierarchical models and GAMs used to determine the drivers of visitor behavior. |

---
