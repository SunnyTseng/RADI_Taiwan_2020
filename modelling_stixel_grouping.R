#################################################################################
### Author: Sunny                                                             ###
### Project: RADI                                                             ###
### Input: data for spliting, environmental predictors to put in the model    ###
###        spliting proportion for training and testing, temporal resolution  ###
###        and stixel height in days                                          ###
### Output: a data frame including training and testing data for each stixels ###
#################################################################################

modelling_stixel_grouping <- function(data = data_sub,
                                      predictors = predictors, 
                                      split = 0.8,
                                      temporal_resolution = 7,
                                      stixel_height = 40){
  
  # data split by 0.2 and 0.8
  set.seed(100)
  ebird_split <- data %>%
    select(observation_count,
           duration_minutes, effort_distance_km, number_observers,
           hour, day, latitude, longitude,
           predictors) %>%
    drop_na() %>%
    split(if_else(runif(nrow(.)) <= split, "train", "test"))
  
  train_all <- tibble()
  test_all <- tibble()
  
  for (i in seq(1, 366, by = temporal_resolution)) {
    if(i < stixel_height/2){
      temporal <- c(seq(1, i + stixel_height/2), seq(366 - (stixel_height/2 - i), 366))
    }else if(i > 366 - stixel_height/2){
      temporal <- c(seq(i - stixel_height/2, 366), seq(1, stixel_height/2 - (366 - i)))
    }else{
      temporal <- seq(i - stixel_height/2, i + stixel_height/2)
    }
    
    # negative binomial from training dataset
    train <- ebird_split$train %>%
      filter(.$day %in% temporal) %>%
      mutate(represent_day = i)
    
    train_all <- rbind(train_all, train)
    
    # negative binomial evaluation from testing dataset
    test <- ebird_split$test %>%
      filter(.$day %in% temporal) %>%
      mutate(represent_day = i)
    
    test_all <- rbind(test_all, test)
  }
  
  stixels <- train_all %>%
    group_nest(represent_day) %>%
    rename(train_data = data) %>%
    left_join(test_all %>% group_nest(represent_day), by = "represent_day") %>%
    rename(test_data = data, day_of_year = represent_day)
  
return(stixels)
}

