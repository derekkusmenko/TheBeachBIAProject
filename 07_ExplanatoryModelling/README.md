# 07 Explanatory Modelling

This directory contains statistical modeling for the Beach BIA visitor analysis. We aim to quantify the drivers of human movement (Bike Share trips) in the area.

## Key Components

### 1. Model Scripts & Notebooks
* **BikeTrips_ModelBayes.qmd**: Implementation of Bayesian models to account for uncertainty in weather effects and temporal trends.
* **BikeTrips_ModelGAM.qmd**: Generalized Additive Models (GAMs) used to capture non-linear relationships, specifically for seasonal effects and temperature thresholds.
* **BikeTrips_SeasonDates.qmd**: Logic for defining the business seasons for The Beach BIA.

### 2. Model Objects (.rds)
*These files are serialized R objects containing trained models. They are ignored by Git in some configurations due to size*

* **fit_bayes_final.rds**: The final converged Bayesian model used for the presentation.
* **fit_user_split.rds**: Model results segmented by user type (Annual Member vs. Casual Rider).
* **model_data_2025.rds**: The specific subset of cleaned data used to train the final iterations of the 2025 models.