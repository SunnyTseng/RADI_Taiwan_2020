#####################
### Author: Sunny ###
### Project: RADI ###
#####################

###############
### Library ###
###############
# data management
library(tidyverse) 
library(data.table)
library(here)
library(lubridate)
library(janitor)
library(furrr)
library(ranger)
library(Boruta)

# GIS related 
library(dggridR)
library(scam)
library(PresenceAbsence)
library(verification)
library(fields)
library(gridExtra)
library(raster)
library(rgdal)
library(sf)
library(twmap)

# plot related
library(RColorBrewer)
library(lattice)
library(ggcorrplot)
library(plotly)

#################
### Functions ###
#################
# resolve namespace conflicts
select <- dplyr::select
map <- purrr::map
projection <- raster::projection

# functions for different steps
source(here("R", "data_preparation_ebird.R"))
source(here("R", "data_preparation_predictors.R"))
source(here("R", "data_preparation_prediction_surface.R"))
source(here("R", "data_preparation_target_species.R"))
source(here("R", "modelling_random_forest.R"))
source(here("R", "modelling_stixel_grouping.R"))
source(here("R", "modelling_GAM.R"))
source(here("R", "modelling_evaluation.R"))
source(here("R", "prediction_maps.R"))

########################
### Data Preparation ###
########################
### cleaned data for eBird and predictors, umcommend when needed
data_preparation_ebird(EBD = here("data", "raw", "Taiwan_ebd", "ebd_TW_relMar-2020", "ebd_TW_relMar-2020.txt"), 
                       path = here("data", "processed", "data_eBird_qualified.csv"),
                       start_year = 2015,
                       effort_max_distance = 5,
                       effort_max_duration = 300,
                       effort_max_observers = 10)

### cleaned predictors data according to the eBird checklists, umcommend when needed
data_preparation_predictors(dir_tiff = here("data", "raw", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                            dir_eBird = here("data", "processed", "data_eBird_qualified.csv"),
                            path = here("data", "processed", "data_eBird_qualified_predictors.csv"))

### prediction surface for making predictions, umcommend when needed
data_preparation_prediction_surface(dir_tiff = here("data", "raw", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                                    path_data_frame = here("data", "processed", "prediciton_surface.csv"),
                                    path_tif = here("data", "processed", "prediction_surface.tif"))

### define target species and save the data for target species, umcommend when needed

data_preparation_target_species(dir_eBird = here("data", "processed", "data_eBird_qualified.csv"),
                               dir_predictors = here("data", "processed", "data_eBird_qualified_predictors.csv"),
                               target_species = "Heterophasia auricularis",
                               path = here("data", "processed", paste0("data_eBird_qualified_combined_", "Heterophasia auricularis", ".csv")))


##########################
### Variable selection ###
##########################

target_species <- "Heterophasia auricularis"

# import data

data <- read_csv(here("data", "processed", target_species,
                      paste0("data_eBird_qualified_combined_", target_species, ".csv")))

data <- data %>%
  mutate(detection = detection %>% as.factor(),
         protocol_type = protocol_type %>% as.factor(),
         other_proad = other_proad %>% as.factor(),
         year = year %>% as.factor())

# sub sampling
set.seed(100)
data_sub <- data %>%
  drop_na() %>%
  mutate(cell = dgGEO_to_SEQNUM(dgconstruct(spacing = 1), longitude, latitude)$seqnum) %>%
  group_by(detection, day, year, cell) %>%
  sample_n(size = 1, replace = TRUE) %>%
  ungroup()


# predictors selection, would take a while :)
predictors <- modelling_random_forest(data = data_sub, 
                                      method = "ranger",
                                      cor_threshold = 0.8,
                                      max_vars = 20)

#####################################
### Data split and create stixels ###
#####################################
stixels <- modelling_stixel_grouping(data = data_sub,
                                     predictors = predictors,
                                     split = 0.8,
                                     temporal_resolution = 7,
                                     stixel_height = 40)

##################################
### Model training and testing ###
##################################

nb <- modelling_GAM(stixels = stixels %>% head(1), family = "nb", predictors = predictors, workers = 16)
ziplss <- modelling_GAM(stixels = stixels, family = "ziplss", predictors = predictors, workers = 16)
models <- inner_join(nb, ziplss %>% select(day_of_year, m_ziplss), by = "day_of_year")
rm(nb)
rm(ziplss) # Time difference of 29.26519 mins

models_test <- modelling_evaluation(models = models, family = "nb", workers = 16) 


#######################################
### Prediction using selected model ###
### Visualization of maps           ###
#######################################

models_map_nb <- prediction_maps(models = nb,
                                 family = "nb",
                                 workers = 16,
                                 duration_minutes = 60,
                                 effort_distance_km = 1, 
                                 number_observers = 1, 
                                 hour = 6,
                                 dir_pred_surf = here("data", "processed", "prediciton_surface.csv"),
                                 dir_pred_tif = here("data", "processed", "prediction_surface.tif"),
                                 quantile = 0.2)
                                     
### Abundance maps
for(i in 1:53){
  png(here("data", "processed", target_species,
           paste0(target_species, "_abd_week_", i, ".png")), 
      res = 300, width = 3, height = 4, units = 'in')
  print(models_map_ziplss$map_ziplss[[i]])
  dev.off()
}

save(predictors, models_test, models_map_nb, 
     file = here("data", "processed", target_species, paste0(target_species, ".RData")))
