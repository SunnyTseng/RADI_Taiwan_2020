###############################################################
### Author: Sunny                                           ###
### Project: RADI                                           ###
### Input: models, family of the model, number of CPU cores ###
### Output: a dataframe with mutated predictions            ###
###############################################################

modelling_evaluation <- function(models = models, family = "nb", workers = 2){

  # model training and testing -- might need parallel programing
  # Set a "plan" for how the code should run.
  plan(multisession, workers = workers)
  inv_link <- binomial(link = "cloglog")$linkinv
  
  if(family == "nb"){
    result1 <- models %>%
      mutate(test_pred_nb = future_map2(.x = test_data, .y = m_nb, .f = ~ predict(.y, newdata = .x, type = "link", se.fit = TRUE) %>%
                                          as_tibble() %>%
                                          transmute(abd = .y$family$linkinv(fit)) %>%
                                          bind_cols(.x) %>%
                                          select(latitude, longitude, abd, observation_count)))
    
  } else {
    result1 <- models %>%
      mutate(test_pred_ziplss = future_map2(.x = test_data, .y = m_ziplss, .f = ~ predict(.y, newdata = .x, type = "link") %>%
                                              as.data.frame() %>%
                                              transmute(abd = inv_link(V2) * exp(V1)) %>%
                                              bind_cols(.x) %>%
                                              select(latitude, longitude, abd, observation_count)))
  }
  return(result1)
}
