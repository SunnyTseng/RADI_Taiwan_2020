###########################################################################
### Author: Sunny Tseng                                                 ###
### Project: RADI                                                       ###
### Input: name of the dataset includings columns as y and x variables  ###
### Output: the selected variables from random forest                   ###
###########################################################################
# method can be either "ranger" or "Boruta", the Boruta package could take up to 4 hours to run

modelling_random_forest <- function(data = data_sub, 
                                    method = "ranger", 
                                    cor_threshold = 0.8,
                                    max_vars = 15){

  data_sub_rf <- data %>%
    select(detection, 
           duration_minutes, effort_distance_km, number_observers, hour, 
           starts_with("dtm"), starts_with("climate"), starts_with("landuse"), starts_with("other")) %>%
    select(-c(climate_2010s_prec, climate_2010s_temp, climate_2010s_tmax, climate_2010s_tmin, climate_2010s_tra)) %>%
    drop_na() 

  detection_freq <- data_sub_rf$detection %>% as.character() %>% as.numeric() %>% mean()

  if (method == "Boruta") {
    rf <- Boruta(formula = detection ~ ., data = data_sub_rf)
    pi <- test %>%
      TentativeRoughFix() %>%
      attStats() %>%
      as.data.frame() %>%
      setDT(keep.rownames = "predictor") %>%
      as_tibble() %>%
      select(predictor, meanImp) %>%
      rename(importance = meanImp) %>%
      arrange(desc(importance)) 
     
  }else if (method == "ranger") {
     rf <- ranger(formula = detection ~ .,
               data = data_sub_rf,
               importance = "impurity",
               probability = TRUE,
               replace = TRUE,
               sample.fraction = c(detection_freq, detection_freq))
    
    pi <- enframe(rf$variable.importance, "predictor", "importance") %>%
      arrange(desc(importance)) 
  }
  
  
  predictors <- pi$predictor[1]
  for (i in pi$predictor[1:max_vars]){
    target <- data_sub %>% select(all_of(i))
    comparison <- data_sub %>% select(all_of(predictors))
    correlations <- cor(target, comparison)
    
    if(all(abs(correlations) < cor_threshold)){
      predictors <- c(predictors, i)
    }
  }
  
return(predictors)
}
