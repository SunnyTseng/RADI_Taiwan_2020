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
source(here("R", "modelling_random_forest_1.R"))
source(here("R", "modelling_stixel_grouping.R"))
source(here("R", "modelling_GAM.R"))
source(here("R", "prediction_maps.R"))

########################
### Data Preparation ###
########################
### cleaned data for eBird and predictors, umcommend when needed
data_preparation_ebird(EBD = "ebd_TW_relMar-2020", 
                       path = here("data", "main_processed_20201116", "data_eBird_qualified.csv"))

### cleaned predictors data according to the eBird checklists, umcommend when needed
data_preparation_predictors(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                            dir_eBird = here("data", "main_processed_20201116", "data_eBird_qualified.csv"),
                            path = here("data", "main_processed_20201116", "data_eBird_qualified_predictors.csv"))

### prediction surface for making predictions, umcommend when needed
data_preparation_prediction_surface(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                                    path_data_frame = here("data", "main_processed_20201116", "prediciton_surface.csv"),
                                    path_tif = here("data", "main_processed_20201116", "prediction_surface.tif"))

### define target species and save the data for target species, umcommend when needed
data_preparation_target_species(dir_eBird = here("data", "main_processed_20201116", "data_eBird_qualified.csv"),
                               dir_predictors = here("data", "main_processed_20201116", "data_eBird_qualified_predictors.csv"),
                               target_species = "Myiomela leucura",
                               path = here("data", "main_processed_20201116", paste0("data_eBird_qualified_combined_", target_species, ".csv")))

##########################
### Variable selection ###
##########################
# import data
target_species <- "Myiomela leucura"
data <- read_csv(here("data", "main_processed_20201116", paste0("data_eBird_qualified_combined_", target_species, ".csv")))
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
  group_by(detection, day, cell) %>%
  sample_n(size = 1, replace = TRUE) %>%
  ungroup()


# predictors selection, would take a while :)
predictors <- modelling_random_forest(data = data_sub, 
                                      method = "ranger",
                                      cor_threshold = 0.8,
                                      max_vars = 20)

#predictors <- modelling_random_forest_1(variables = here("R", "pi_Boruta.csv"),
#                                        cor_threshold = 0.8,
#                                        max_vars = 15)

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

nb <- modelling_GAM(stixels = stixels, family = "nb", predictors = predictors, workers = 2)
ziplss <- modelling_GAM(stixels = stixels, family = "ziplss", predictors = predictors, workers = 8)
models <- inner_join(nb, ziplss %>% select(day_of_year, m_ziplss), by = "day_of_year")
rm(nb)
rm(ziplss) # Time difference of 29.26519 mins

models_test <- modelling_evaluation(models = models, family = "nb", workers = 2) 
models_test <- modelling_evaluation(models = models_test, family = "ziplss", workers = 2) 


#######################################
### Prediction using selected model ###
### Visualization of maps           ###
#######################################

models_map_nb <- prediction_maps(models = models_test,
                                 family = "nb",
                                 workers = 8,
                                 duration_minutes = 60,
                                 effort_distance_km = 1, 
                                 number_observers = 1, 
                                 hour = 6,
                                 dir_pred_surf = here("data", "main_processed", "prediciton_surface.csv"),
                                 dir_pred_tif = here("data", "main_processed", "prediction_surface.tif"),
                                 quantile = 0.2)
                                     

models_map_ziplss <- prediction_maps(models = models_test,
                                 family = "ziplss",
                                 workers = 8,
                                 duration_minutes = 60,
                                 effort_distance_km = 1, 
                                 number_observers = 1, 
                                 hour = 6,
                                 dir_pred_surf = here("data", "main_processed", "prediciton_surface.csv"),
                                 dir_pred_tif = here("data", "main_processed", "prediction_surface.tif"),
                                 quantile = 0.2)

###
### Objective 1: fine scale information - weekly change of population mean elevation, area coverage
###

### Abundance maps
for(i in 1:53){
  png(here("docs", "plot", paste0("WTRO_abd_quantile_0.2_week_", i, ".png")), res = 300, width = 3, height = 4, units = 'in')
  print(models_map_ziplss$map_ziplss[[i]])
  dev.off()
}

dtm <- here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip", "GeoTIFF_epsg3826_DTM", "G1km_TWD97-121_DTM_ELE.tif") %>%
  raster()

area_change <- models_map_nb %>%
  mutate(area = map2_dbl(.x = threshold, .y = map_pred_nb, .f = ~ .y %>% 
                           filter(abd > .x) %>%
                           dim() %>%
                           .[1]),
         area_diff = (area- lag(area))/area) %>%
  mutate(season = cut(day_of_year, 
                      breaks = c(1 , 50 , 92, 211, 316, Inf),
                      right = FALSE,
                      labels = c("NB", "BB", "BR", "AB", "NB"))) 

annual_ele <- area_change %>%
  mutate(ele_data = map2(.x = map_pred_nb, .y = threshold, .f = ~ .x %>%
                          mutate(abd = if_else(abd > .y, abd, 0),
                                 ele = extract(dtm, .x %>% select(x, y) %>% SpatialPoints(proj4string = CRS("+init=epsg:3826"))),
                                 ele_category = cut(ele, breaks = c(seq(0, 2500, by = 250), Inf), include.lowest = TRUE),
                                 abd = ceiling(abd))),
         ele_hist = map(.x = ele_data, .f = ~ .x %>%
                          map2(.x = .$abd, .y = .$ele, .f = ~ rep(.y, times = .x)) %>% 
                          flatten_dbl() %>%
                          as_tibble(.)),
         ele_average = map_dbl(.x = ele_hist, .f = ~ .x %>% pull(value) %>% mean()),
         ele_Q1 = map_dbl(.x = ele_hist, .f = ~ .x %>% pull(value) %>% quantile(0.25)),
         ele_Q3 = map_dbl(.x = ele_hist, .f = ~ .x %>% pull(value) %>% quantile(0.75))) %>%
  select(day_of_year, season, ele_average, ele_Q1, ele_Q3) 

# area change during the year
ggplot(area_change) +
  #geom_smooth(aes(x = day_of_year, y = area), se = FALSE, span = 0.3, color = "black", linetype = "dashed") +
  geom_point(aes(x = day_of_year, y = area, fill = season), size = 5, shape = 21) +
  scale_fill_manual(values = c(NB = "#154e70", BB = "#fff2cc", BR = "#9a3c2e", AB = "#fff2cc")) +
  theme_bw()

# elevation change during the year
ggplot(annual_ele, aes(x = day_of_year, y = ele_average)) +
  #geom_smooth(aes(x = day_of_year, y = area), se = FALSE, span = 0.3, color = "black", linetype = "dashed") +
  #geom_errorbar(aes(ymin = ele_Q1, ymax = ele_Q3), width=.2) +
  geom_point(aes(fill = season), size = 5, shape = 21) +
  scale_fill_manual(values = c(NB = "#154e70", BB = "#fff2cc", BR = "#9a3c2e", AB = "#fff2cc")) +
  theme_bw()



###
### Objective 2: broad scale information - elevation distribution and coverage in breeding and non-breeding season
###

abd_season <- area_change %>%
  group_nest(season) %>%
  mutate(abd_season = map(.x = data, .f = ~ .x$map_pred_nb %>% 
                            reduce(., inner_join, by = c("x", "y")) %>%
                            mutate(average = rowMeans(select(., starts_with("abd")))) %>%
                            select(x, y, average)),
         threshold = map_dbl(.x = data, .f = ~ .x$threshold %>% mean())) 

abd_season_map <- abd_season %>%
  filter(season == "BB" | season == "NB") %>%
  select(abd_season) %>%
  map_df(.x = ., .f = ~ .x %>% reduce(., inner_join, by = c("x", "y"))) %>%
  rename(BB_red = average.y, NB_green = average.x) %>%
  mutate(BB_red = if_else(BB_red < as.numeric(abd_season[2, 4]), 0, BB_red),
         NB_green = if_else(NB_green < as.numeric(abd_season[1, 4]), 0, NB_green)) %>%
  pivot_longer(cols = c("NB_green", "BB_red"), names_to = "season") 

# Taiwan map for non-breeding season
ggplot() +
  geom_tile(data = abd_season_map, aes(x = x, y = y), fill = "#e6e6e6") +
  geom_tile(data = abd_season_map %>% filter(value != 0 & season == "NB_green"), 
            aes(x = x, y = y, fill = value)) +
  scale_fill_gradient2(trans = "log",
                       low = "#abbeca",
                       mid = "#3e7da2",
                       high = "#154e70",
                       breaks = c(0, 2, 50),
                       limits = c(from = 0.01, to = 50)) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_blank(),
        axis.title = element_blank(), axis.text = element_blank(),
        axis.ticks = element_blank())

# Taiwan map for breeding season
ggplot() +
  geom_tile(data = abd_season_map, aes(x = x, y = y), fill = "#e6e6e6") +
  geom_tile(data = abd_season_map %>% filter(value != 0 & season == "BB_red"), 
            aes(x = x, y = y, fill = value)) +
  scale_fill_gradient2(trans = "log",
                       low = "#d8b8b4",
                       mid = "#cf695a",
                       high = "#9a3c2e",
                       breaks = c(0, 2, 50),
                       limits = c(from = 0.01, to = 50)) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_blank(),
        axis.title = element_blank(), axis.text = element_blank(),
        axis.ticks = element_blank())

abd_season_distribution <- abd_season %>%
  mutate(ele = map(.x = abd_season, .f = ~ .x %>%
                     mutate(ele = extract(dtm, .x %>% select(x, y) %>% SpatialPoints(proj4string = CRS("+init=epsg:3826")))) %>% 
                     mutate(ele_category = cut(ele, breaks = c(seq(0, 2500, by = 250), Inf), include.lowest = TRUE)) %>%
                     group_by(ele_category) %>%
                     summarise(abd_sum = sum(average)) %>%
                     mutate(abd_sum_relative = abd_sum/sum(abd_sum))))

# elevation histogram for non-breeding season
ggplot(data = abd_season_distribution$ele[[1]], aes(x = ele_category, y = abd_sum_relative)) +
  geom_bar(stat = "identity", colour = "black", fill = "#154e70") +
  ylim(0, 0.3) +
  theme_bw()

# elevation histogram for breeding season
ggplot(data = abd_season_distribution$ele[[3]], aes(x = ele_category, y = abd_sum_relative)) +
  geom_bar(stat = "identity", colour = "black", fill = "#9a3c2e") +
  ylim(0, 0.3) +
  theme_bw()

season_ele <- abd_season %>%
  mutate(ele_data = map2(.x = abd_season, .y = threshold, .f = ~ .x %>%
                          mutate(abd = if_else(average > .y, average, 0),
                                 ele = extract(dtm, .x %>% select(x, y) %>% SpatialPoints(proj4string = CRS("+init=epsg:3826"))),
                                 ele_category = cut(ele, breaks = c(seq(0, 2500, by = 250), Inf), include.lowest = TRUE),
                                 abd = ceiling(abd)))) %>%
  mutate(ele_hist = map(.x = ele_data, .f = ~ .x %>%
                          map2(.x = .$abd, .y = .$ele, .f = ~ rep(.y, times = .x)) %>% 
                          flatten_dbl() %>%
                          as_tibble(.))) %>%
  select(season, ele_hist) %>%
  filter(season == "BR" | season == "NB") %>%
  unnest(ele_hist) %>%
  mutate(season_dbl = if_else(season == "NB", 0.7, 0.85),
         category = "category")


# elevation distribution of breeding and non-breeding season
ggplot(data = season_ele, aes(x = season, y = value, fill = season, colour = season)) +
  #geom_flat_violin(position = position_nudge(x = .25, y = 0), adjust = 2, trim = FALSE) +
  geom_point(aes(x = category, y = value, fill = season, colour = season),
             position = position_jitter(width = .1), size = .05, shape = 16, alpha = 0.2) +
  geom_boxplot(aes(x = season_dbl + 0.25, y = value), 
               outlier.shape = NA, width = .1, colour = "BLACK", size = 0.8,
               position = position_nudge(x = .25, y = 0)) +
  ylab("Elevation") +
  xlab("Season") +
  theme_cowplot() +
  guides(fill = FALSE, colour = FALSE) +
  scale_colour_manual(values = c("#154e70", "#9a3c2e")) +
  scale_fill_manual(values = c("#154e70", "#9a3c2e")) 
  
# elevation distribution of breeding and non-breeding season
ggplot(data = season_ele, aes(x = category, y = value, fill = season, group = season)) +
  geom_flat_violin(aes(fill = season), position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = .5, colour = NA)+
  scale_colour_manual(values = c("#154e70", "#9a3c2e")) +
  scale_fill_manual(values = c("#154e70", "#9a3c2e")) +
  ggtitle("Figure 10: Repeated Measures Factorial Rainclouds") +
  theme_cowplot()


#####################
### Visualization ###
#####################

### distribution of checklists before and after subsampling
sub_before <- tw_county %>%
  st_crop(xmin = 119, xmax = 123, ymin = 20, ymax = 26) %>%
  ggplot() +
  geom_sf(size = 0.1) +
  geom_point(data = filter(data, detection == 0), aes(x = longitude, y = latitude), size = 0.05, colour = "grey39", alpha = 0.4) +
  geom_point(data = filter(data, detection == 1), aes(x = longitude, y = latitude), size = 0.05, colour = "forestgreen", alpha = 0.4) +
  theme_bw() 

### stixels visualization

structure <- stixels %>%
  mutate(n_training = map_dbl(.x = train_data, .f = ~ dim(.x)[1]),
         n_training_detection = map_dbl(.x = train_data, .f = ~ .x %>% filter(observation_count != 0) %>% dim() %>% .[1]),
         n_training_non_detection = map_dbl(.x = train_data, .f = ~ .x %>% filter(observation_count == 0) %>% dim() %>% .[1]),
         rate = n_training_detection/n_training)


### model evaluation
model_eval <- models %>%
  mutate(RMSE_train = map_dbl(.x = m_nb, .f = ~ .x$residuals %>% .**2 %>% mean() %>% sqrt()),
         RMSE_test = map_dbl(.x = test_pred_nb, .f = ~ (.x$abd - .x$observation_count) ** 2 %>% mean() %>% sqrt()),
         deviance_explained = map_dbl(.x = m_nb, .f = ~ (.x$deviance/.x$null.deviance)),
         n_training = map_dbl(.x = train_data, .f = ~ dim(.x)[1]),
         n_training_detection = map_dbl(.x = train_data, .f = ~ .x %>% filter(observation_count != 0) %>% dim() %>% .[1]),
         n_training_non_detection = map_dbl(.x = train_data, .f = ~ .x %>% filter(observation_count == 0) %>% dim() %>% .[1]))

ggplot(data = model_eval, aes(x = day_of_year)) +
  geom_line(aes(y = n_training_non_detection), size = 1.5, colour = "steelblue4") +
  geom_line(aes(y = n_training_detection*20), size = 1.5, colour = "steelblue1") +
  #geom_line(aes(y = RMSE_test*10000, colour = "Testing"), size = 1, colour = "red", linetype = "dashed") +
  scale_y_continuous(sec.axis = sec_axis(~./20, name = "Detection")) +
  theme_bw()

ggplot(data = model_eval, aes(x = day_of_year)) +
  geom_line(aes(y = RMSE_test), size = 1, colour = "thistle2") +
  geom_line(aes(y = deviance_explained), size = 1, colour = "skyblue1") +
  theme_bw()




