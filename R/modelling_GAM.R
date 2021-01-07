#########################################################################
### Author: Sunny                                                     ###
### Project: RADI                                                     ###
### Input: stixels, environmental predictors to include in the model, ###
###        family of the model, number of CPU cores                   ###
### Output: a gam formula                                             ###
#########################################################################

modelling_GAM <- function(stixels = stixels, family = "nb", predictors = predictors, workers = 1){
  
  # k is a gam parameters
  # degrees of freedom for smoothing
  k <- 5
  # degrees of freedom for cyclic time of day smooth
  k_time <- 7 
  
  time_knots <- list(time_observations_started = seq(0, 24, length.out = k_time))
  
  # continuous predictors
  # hold out time to treat seperately since it's cyclic
  continuous_covs <- stixels$train_data[[1]] %>%
    select(observation_count,
           duration_minutes, effort_distance_km, number_observers,
           hour, day, latitude, longitude,
           predictors) %>%
    select(-observation_count, 
           -hour, -day, -latitude, -longitude) %>% 
    names()
  
  # create model formula for predictors
  gam_formula_rhs <- str_glue("s({var}, k = {k})", 
                              var = continuous_covs, k = k) %>% 
    str_flatten(collapse = " + ") %>% 
    str_glue(" ~ ", .,
             "+ s(hour, bs = \"cc\", k = {k})", 
             k = k_time) %>% 
    as.formula()
  
  # model formula including response
  gam_formula <- update.formula(observation_count ~ ., gam_formula_rhs)
  
  
  # model training and testing -- might need parallel programing
  # Set a "plan" for how the code should run.
  plan(multisession, workers = workers)
  
  inv_link <- binomial(link = "cloglog")$linkinv
  
  if(family == "nb"){
    result1 <- stixels %>%
      mutate(m_nb = future_map(.x = train_data, .f = ~ gam(gam_formula,
                                                           data = .x,
                                                           family = "nb",
                                                           knots = time_knots)))
    # result2 <- result1 %>%
    #   mutate(test_pred_nb = future_map2(.x = test_data, .y = m_nb, .f = ~ predict(.y, newdata = .x, type = "link", se.fit = TRUE) %>%
    #                                       as_tibble() %>%
    #                                       transmute(abd = .y$family$linkinv(fit)) %>%
    #                                       bind_cols(.x) %>%
    #                                       select(latitude, longitude, abd, observation_count))) 
    
  } else {
    result1 <- stixels %>%
      mutate(m_ziplss = future_map(.x = train_data, 
                                   .f = ~ tryCatch({
        gam(list(gam_formula, 
                 gam_formula[-2]),
            data = .x,
            family = "ziplss",
            knots = time_knots)
        },
        warning = function( ) {
          NULL
        },
        error = function(msg) {
          message("Original error message:")
          message(paste0(msg,"\n"))
          return(NA)
        })))
    
    # result2 <- result1 %>%
    #   mutate(test_pred_ziplss = if_else(is.na(m_ziplss), NA, future_map2(.x = test_data, .y = m_ziplss, .f = ~ predict(.y, newdata = .x, type = "link") %>%
    #                                                                       as.data.frame() %>%
    #                                                                       transmute(abd = inv_link(V2) * exp(V1)) %>%
    #                                                                       bind_cols(.x) %>%
    #                                                                       select(latitude, longitude, abd, observation_count))))
  }
return(result1)
}
