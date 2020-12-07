############################################################################
### Author: Sunny                                                        ###
### Project: RADI                                                        ###
### Input: file name of the downloaded eBird Basic Dataset (EBD)         ###
### Output: none, but save the claned file in the folder                 ###
############################################################################

data_preparation_ebird <- function(EBD = "ebd_TW_relMar-2020", 
                                   path = here("data", "main_processed_20201116", "data_eBird_qualified.csv")){
  data <- fread(file = here("data", "Taiwan_ebd", EBD, paste0(EBD, ".txt")), 
              encoding = "UTF-8",
              select = c(1:6, 9, 15, 16, 24:40),
              quote="")

  # data cleaning, formating, and filtering
  data_cleaned <- data  %>%
    as_data_frame() %>%
    clean_names() %>%
    mutate(year = observation_date %>% year(),
           month = observation_date %>% month(),
           week = observation_date %>% week(),
           day = observation_date %>% yday(),
           hour = time_observations_started %>% hms() %>% hour(),
           observation_count = observation_count %>% as.numeric(),
           filt = paste0(common_name, group_identifier)) 
  rm(data)
 
  # data_filtered <- data_cleaned %>%
  #   filter(year >= 2015,
  #          protocol_type == "Traveling" | protocol_type == "Stationary" | protocol_type == "Area",
  #          all_species_reported == 1,
  #          effort_distance_km <= 10 | effort_area_ha <= 5626,
  #          duration_minutes <= 1440) %>%
  #   drop_na("time_observations_started", "duration_minutes", "protocol_type", "number_observers", "effort_distance_km", "observation_count") %>%
  #   filter(group_identifier == "" | !duplicated(filt)) %>%
  #   dplyr::select(-31)

  data_filtered <- data_cleaned %>%
    filter(year >= 2015,
           protocol_type == "Traveling" & effort_distance_km <= 5,
           all_species_reported == 1,
           duration_minutes <= 300,
           number_observers <= 10) %>%
    drop_na("observation_count", "time_observations_started", "longitude", "latitude", "protocol_type", "duration_minutes", "number_observers") %>%
    filter(group_identifier == "" | !duplicated(filt)) %>%
    dplyr::select(-"filt")
  
  rm(data_cleaned)

write_csv(data_filtered, path)
}
