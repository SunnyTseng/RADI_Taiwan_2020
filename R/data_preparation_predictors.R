#####################################################################
### Author: Sunny                                                 ###
### Project: RADI                                                 ###
### Input: directory of GIS layers and eBird qualified checklists ### 
### output: the values of the GIS layers at each locations        ### 
#####################################################################

data_preparation_predictors <- function(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                                        dir_eBird = here("data", "main_processed", "data_eBird_qualified.csv"),
                                        path = here("data", "main_processed", "data_eBird_qualified_predictors.csv")){
  
  # make the list of all 100 geotiff raster file
  geo_tiff_3826 <- list.files(dir_tiff, pattern = "3826") %>%
    paste0(dir_tiff, "/", .) %>%
    map(.x = ., .f = ~ paste0(.x, "/", list.files(.x))) %>%
    flatten_chr()
  
  geo_tiff_3825 <- list.files(dir_tiff, pattern = "3825") %>%
    paste0(dir_tiff, "/", .) %>%
    map(.x = ., .f = ~ paste0(.x, "/", list.files(.x))) %>%
    flatten_chr()
  
  predictors <- geo_tiff_3826 %>%
    str_extract(pattern = "(?<=121_).+.(?=\\.)") %>%
    make_clean_names()
  
  # extract the remote sensing data to each of the coordinate
  data_filtered <- read_csv(dir_eBird)
  
  observation_coors <- data_filtered %>%
    select(longitude, latitude) %>%
    SpatialPoints(proj4string = CRS("+init=epsg:4326"))
  
  value_df <- data_filtered %>% select(global_unique_identifier)
  for(i in 1:(predictors %>% length())){
    value_3826 <- extract(geo_tiff_3826[i] %>% raster(), observation_coors)
    value_3825 <- extract(geo_tiff_3825[i] %>% raster(), observation_coors)
    value <- coalesce(value_3826, value_3825) %>% as_tibble()
    value_df <- bind_cols(value_df, value)
  }
  
  names(value_df)[-1] <- predictors
  value_df <- value_df %>% as_tibble()
  write_csv(value_df, path)
}