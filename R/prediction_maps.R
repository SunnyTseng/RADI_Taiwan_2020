###############
### Author: Sunny
### Project: RADI
### set threshold and create maps from prediction models
##############

prediction_maps <- function(models = models,
                            family = "nb",
                            workers = 8,
                            duration_minutes = 60, 
                            effort_distance_km = 1, 
                            number_observers = 1, 
                            hour = 6,
                            dir_pred_surf = here("data", "main_processed", "prediciton_surface.csv"),
                            dir_pred_tif = here("data", "main_processed", "prediction_surface.tif"),
                            quantile = 0.1){
  
  plan(multisession, workers = workers)
  
  # prediction surface 
  pred_surf <- read_csv(dir_pred_surf)
  pred_surf <- pred_surf %>%
    drop_na() %>%
    mutate(duration_minutes = duration_minutes,
           effort_distance_km = effort_distance_km,
           number_observers = number_observers,
           hour = hour)
  
  r <- raster(dir_pred_tif)
  
  # function for extracting threshold
  thre <- function(data_values, data_checklists){
    # coordinates for setting threshold
    observation_coors <- data_checklists %>%
      filter(observation_count >= 1) %>%
      select(longitude, latitude) %>%
      SpatialPoints(proj4string = CRS("+init=epsg:4326"))
    
    values <- data_values %>%
      select(x, y) %>%
      SpatialPoints(proj4string = CRS("+init=epsg:3826")) %>%
      rasterize(., r, field = data_values$abd) %>%
      extract(x = ., y = observation_coors)
    
    values <- values[!is.na(values)] %>%
      quantile(quantile)
    
    return(values)
  }
  
  # main code here
  if (family == "nb"){
    map_pred <- models %>%
      mutate(map_pred_nb = map(.x = m_nb, .f = ~ predict(.x, newdata = pred_surf, type = "link", se.fit = TRUE) %>%
                                 as_tibble() %>%
                                 transmute(abd = .x$family$linkinv(fit)) %>%
                                 bind_cols(pred_surf) %>%
                                 select(x, y, abd))) 
    
    threshold <- map_pred %>%
      mutate(threshold = map2_dbl(.x = map_pred_nb, .y = train_data, 
                                  .f = ~ thre(data_values = .x, data_checklists = .y)))
    
    
    cols <- c("#febd2a", "#fa9e3c", "#f1824d", "#e66d5d", "#d6546e",
              "#c43e7f", "#ac2693", "#9310a1", "#7702a8", "#5702a5", "#360498",
              "#0d0887")
    
    from = threshold$threshold %>% min()
    
    map_pred_plot <- threshold %>%
      mutate(map_nb = map2(.x = map_pred_nb, .y = threshold, .f = ~ ggplot() +
                             geom_tile(data = .x, aes(x = x, y = y), fill = "#e6e6e6") +
                             geom_tile(data = .x %>% filter(abd > .y),
                                       aes(x = x, y = y, fill = abd)) +
                             scale_fill_gradientn(trans = "log",
                                                  colours = cols,
                                                  breaks = c(0, 2, 50),
                                                  limits = c(from = from, to = 100)) +
                             #geom_sf(data = tw_county %>%
                             #          st_crop(xmin = 119, xmax = 123, ymin = 20, ymax = 26) %>%
                             #          st_transform(crs = 3826),
                             #          col = "white", fill = NA, size = 0.3) +
                             theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                   panel.background = element_blank(), axis.line = element_blank(),
                                   axis.title = element_blank(), axis.text = element_blank(),
                                   axis.ticks = element_blank()))) %>%
      select(day_of_year, threshold, map_pred_nb, map_nb)
    
  } else {
    
    inv_link <- binomial(link = "cloglog")$linkinv
    
    map_pred <- models %>%
      mutate(map_pred_ziplss = map(.x = m_ziplss, .f = ~ predict(.x, newdata = pred_surf, type = "link") %>%
                                     as.data.frame() %>%
                                     transmute(abd = inv_link(V2) * exp(V1)) %>%
                                     bind_cols(pred_surf) %>%
                                     select(x, y, abd))) 
    threshold <- map_pred %>%
      mutate(threshold = map2_dbl(.x = map_pred_ziplss, .y = train_data, 
                                  .f = ~ thre(data_values = .x, data_checklists = .y)))
    
    
    cols <- c("#febd2a", "#fa9e3c", "#f1824d", "#e66d5d", "#d6546e",
              "#c43e7f", "#ac2693", "#9310a1", "#7702a8", "#5702a5", "#360498",
              "#0d0887")
    
    from = threshold$threshold %>% min()
    
    map_pred_plot <- threshold %>%
      mutate(map_ziplss = map2(.x = map_pred_ziplss, .y = threshold, .f = ~ ggplot() +
                             geom_tile(data = .x, aes(x = x, y = y), fill = "#e6e6e6") +
                             geom_tile(data = .x %>% filter(abd > .y),
                                       aes(x = x, y = y, fill = abd)) +
                             scale_fill_gradientn(trans = "log",
                                                  colours = cols,
                                                  breaks = c(0, 2, 50),
                                                  limits = c(from = from, to = 100)) +
                             #geom_sf(data = tw_county %>%
                             #          st_crop(xmin = 119, xmax = 123, ymin = 20, ymax = 26) %>%
                             #          st_transform(crs = 3826),
                             #          col = "white", fill = NA, size = 0.3) +
                             theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                   panel.background = element_blank(), axis.line = element_blank(),
                                   axis.title = element_blank(), axis.text = element_blank(),
                                   axis.ticks = element_blank()))) %>%
      select(day_of_year, threshold, map_pred_ziplss, map_ziplss)
  }
  
return(map_pred_plot)
}


  
  