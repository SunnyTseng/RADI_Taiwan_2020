############################################################################
### Author: Sunny                                                        ###
### Project: RADI                                                        ###
### Input: the directory of the geotiff files                            ###
### Output: the prediction data frame and the tif file for calculation   ###
###         and predicted values filling                                 ###
############################################################################

data_preparation_prediction_surface <- function(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                                                path_data_frame = here("data", "main_processed", "prediciton_surface.csv"),
                                                path_tif = here("data", "main_processed", "prediction_surface.tif")){
    
    ###
    ### Prediction surface and prediction surface fitting data
    ###
    geo_tiff_3826 <- list.files(dir_tiff, pattern = "3826") %>%
      paste0(dir_tiff, "/", .) %>%
      map(.x = ., .f = ~ paste0(.x, "/", list.files(.x))) %>%
      flatten_chr()
        
    pred_surf <- geo_tiff_3826[1] %>% raster() %>% rasterToPoints() %>% as_tibble()
    for(i in 2:100){
      value_3826 <- geo_tiff_3826[i] %>% raster() %>% rasterToPoints() %>% as_tibble()
      pred_surf <- full_join(pred_surf, value_3826, by = c("x", "y"))
    }

    names(pred_surf)[c(-1, -2)] <- geo_tiff_3826 %>%
      str_extract(pattern = "(?<=121_).+.(?=\\.)") %>%
      make_clean_names()

    write_csv(pred_surf, path_data_frame)

    ###
    ### Create prediction surface
    ###
    raster2 <- raster(geo_tiff_3826[99]) 
    crs(raster2) <- CRS("+init=epsg:3826")

    raster1 <- pred_surf %>%
      select(c(1, 2, 3)) %>%
      st_as_sf(coords = c("x", "y")) 
    st_crs(raster1) <- 3826

    raster1 <- rasterize(raster1, raster2, field = 1) %>%
      trim()

    writeRaster(raster1, filename = path_tif, overwrite = TRUE)
}
