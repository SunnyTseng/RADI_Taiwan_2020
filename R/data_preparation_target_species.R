#############################################################################
### Author: Sunny                                                         ###
### Project: RADI                                                         ###
### Purpose: Select a specific target species and output a analysis-ready ###
###          dataset for model fitting                                    ###
#############################################################################

data_preparation_target_species <- function(dir_eBird = here("data", "main_processed", "data_eBird_qualified.csv"),
                                            dir_predictors = here("data", "main_processed", "data_eBird_qualified_predictors.csv"),
                                            target_species,
                                            path){
  data_eBird <- read_csv(dir_eBird)
  data_predictors <- read_csv(dir_predictors)
  
  data <- left_join(data_eBird, data_predictors, by = "global_unique_identifier")
  rm(data_eBird)
  rm(data_predictors)
  
  data_detection <- data %>% 
    filter(scientific_name == target_species) %>%
    distinct(sampling_event_identifier, .keep_all = TRUE) %>%
    mutate(detection = 1)
  
  data_no_detection <- data %>%
    filter(!sampling_event_identifier %in% data_detection$sampling_event_identifier) %>%
    filter(!duplicated(sampling_event_identifier)) %>%
    mutate(detection = 0)
  
  data <- bind_rows(data_detection, data_no_detection) %>%
    mutate(observation_count = if_else(detection == 1, observation_count, 0)) %>%
    mutate(climate_2010s_prec = case_when(month == 1 ~ climate_2010s_prec01,
                                          month == 2 ~ climate_2010s_prec02,
                                          month == 3 ~ climate_2010s_prec03,
                                          month == 4 ~ climate_2010s_prec04,
                                          month == 5 ~ climate_2010s_prec05,
                                          month == 6 ~ climate_2010s_prec06,
                                          month == 7 ~ climate_2010s_prec07,
                                          month == 8 ~ climate_2010s_prec08,
                                          month == 9 ~ climate_2010s_prec09,
                                          month == 10 ~ climate_2010s_prec10,
                                          month == 11 ~ climate_2010s_prec11,
                                          month == 12 ~ climate_2010s_prec12),
           climate_2010s_temp = case_when(month == 1 ~ climate_2010s_temp01,
                                          month == 2 ~ climate_2010s_temp02,
                                          month == 3 ~ climate_2010s_temp03,
                                          month == 4 ~ climate_2010s_temp04,
                                          month == 5 ~ climate_2010s_temp05,
                                          month == 6 ~ climate_2010s_temp06,
                                          month == 7 ~ climate_2010s_temp07,
                                          month == 8 ~ climate_2010s_temp08,
                                          month == 9 ~ climate_2010s_temp09,
                                          month == 10 ~ climate_2010s_temp10,
                                          month == 11 ~ climate_2010s_temp11,
                                          month == 12 ~ climate_2010s_temp12),
           climate_2010s_tmax = case_when(month == 1 ~ climate_2010s_tmax01,
                                          month == 2 ~ climate_2010s_tmax02,
                                          month == 3 ~ climate_2010s_tmax03,
                                          month == 4 ~ climate_2010s_tmax04,
                                          month == 5 ~ climate_2010s_tmax05,
                                          month == 6 ~ climate_2010s_tmax06,
                                          month == 7 ~ climate_2010s_tmax07,
                                          month == 8 ~ climate_2010s_tmax08,
                                          month == 9 ~ climate_2010s_tmax09,
                                          month == 10 ~ climate_2010s_tmax10,
                                          month == 11 ~ climate_2010s_tmax11,
                                          month == 12 ~ climate_2010s_tmax12),
           climate_2010s_tmin = case_when(month == 1 ~ climate_2010s_tmin01,
                                          month == 2 ~ climate_2010s_tmin02,
                                          month == 3 ~ climate_2010s_tmin03,
                                          month == 4 ~ climate_2010s_tmin04,
                                          month == 5 ~ climate_2010s_tmin05,
                                          month == 6 ~ climate_2010s_tmin06,
                                          month == 7 ~ climate_2010s_tmin07,
                                          month == 8 ~ climate_2010s_tmin08,
                                          month == 9 ~ climate_2010s_tmin09,
                                          month == 10 ~ climate_2010s_tmin10,
                                          month == 11 ~ climate_2010s_tmin11,
                                          month == 12 ~ climate_2010s_tmin12),
           climate_2010s_tra = case_when(month == 1 ~ climate_2010s_tra01,
                                         month == 2 ~ climate_2010s_tra02,
                                         month == 3 ~ climate_2010s_tra03,
                                         month == 4 ~ climate_2010s_tra04,
                                         month == 5 ~ climate_2010s_tra05,
                                         month == 6 ~ climate_2010s_tra06,
                                         month == 7 ~ climate_2010s_tra07,
                                         month == 8 ~ climate_2010s_tra08,
                                         month == 9 ~ climate_2010s_tra09,
                                         month == 10 ~ climate_2010s_tra10,
                                         month == 11 ~ climate_2010s_tra11,
                                         month == 12 ~ climate_2010s_tra12))
  
  data <- data %>%
    select(detection, observation_count, 
           duration_minutes, protocol_type, effort_distance_km, number_observers,
           hour, week, day, year,
           latitude, longitude,
           starts_with("dtm"), starts_with("climate_2010s_bio"), starts_with("landuse_2010s_"), starts_with("other_"),
           climate_2010s_prec,
           climate_2010s_temp,
           climate_2010s_tmax,
           climate_2010s_tmin,
           climate_2010s_tra)
  
  rm(data_detection)
  rm(data_no_detection)
  
  write_csv(data, path)
  
return(NULL)
}
