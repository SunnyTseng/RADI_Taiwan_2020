# RADI_Taiwan_2020

RADI_Taiwan is a project aiming to create avian species distribution maps using eBird data. The method was adapted from Status and Trends products by Cornell Lab of Ornithology ([Fink et al., 2020](https://esajournals.onlinelibrary.wiley.com/doi/full/10.1002/eap.2056)).

## Products
static data distribution to the animation

## Workflow
workflow corresponding to each of the functions

## Directory Structure
``` bash
|- README.md
|- .here
|- R
|  |- data_preparation_ebird.r
|  |- data_preparation_predictors.r
|  |- data_preparation_prediction_surface.r
|  |- data_preparation_target_species.r
|  |- modelling_random_forest.r
|  |- modelling_stixel_grouping.r
|  |- modelling_GAM.r
|  |- modelling_evaluation.r
|  |- prediction_maps.r
|  |- integrated.r
```


## Functions documentation

***
### **data_preparation_ebird** 
```R
data_preparation_ebird(EBD = "ebd_TW_relMar-2020", 
                       path = here("data", "main_processed_20201116", "data_eBird_qualified.csv"),
                       start_year = 2015,
                       effort_max_distance = 5,
                       effort_max_duration = 300,
                       effort_max_observers = 10)
```
 Argument |  --
--- | --- 
EBD | character, file path which includes eBird basic dataset (EBD) without .txt extension. EBD can be directly downloaded from [eBird website](https://ebird.org/science/download-ebird-data-products) through data request. 
path | character, file path and name with .csv extension for saving the resulted dataset
start_year | numerical, only retain eBird checklists observed after the specified common era year
effort_max_distance | numerical, only retain eBird checklists observed within the specified travelling distance in km.
effort_max_duration | numerical, only retain eBird checklists observed within the specified time duration in minutes.
effort_max_observers | numerical, only retain eBird checklists observed with limited observers.

#### **Description**
Clean and filtered raw eBird Basic Dataset and save a new dataset ready for analysis. Raw EBD data was quite dirty in a way that it includes all the raw information recorded by citizen scientists. In order to enhance the analysis accuracy, the data was cleaned by standarizing variable names, mutating observation year, month, week, day, and hour columns. The columns were converted to proper data types. Further, the data was filtered by year, research efforts. Incomplete and duplicated checklists were removed. 

#### **Value**
A new cleaned and filtered dataset (.csv) saved in specified path.  



***
### **data_preparation_predictors**
```R
data_preparation_predictors(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                            dir_eBird = here("data", "main_processed", "data_eBird_qualified.csv"),
                            path = here("data", "main_processed", "data_eBird_qualified_predictors.csv"))
```
 Argument |  --
--- | --- 
dir_tiff | character, file path of the folder that contains GIS .tif files
dir_eBird | character, file path of the cleaned eBird dataset output by `data_preparation_ebird` function
path | character, file path and name with .csv extension for saving the resulted dataset

#### **Description**
Overlap the GIS layers on eBird checklist locations and extract environmental predictors according to each of the records. In order to link the GIS data with eBird checklist locations, the function overlays the locations on GIS layers and extracted the corresponded values. The values were further saved in a .csv file. 

#### **Value**
A new dataset with extracted 



***
### **data_preparation_prediction_surface**
```R
data_preparation_prediction_surface(dir_tiff = here("data", "Taiwan_environmental_dataset-master", "GeoTIFF_unzip"),
                                    path_data_frame = here("data", "main_processed", "prediciton_surface.csv"),
                                    path_tif = here("data", "main_processed", "prediction_surface.tif"))
```
 Argument |  --
--- | --- 
dir_tiff | character, file path of the folder that contains GIS .tif files
path_data_frame | character, file path and name with .csv extension for saving the resulted dataset
path_tif | character, file path and name with .tif extension for saving the resulted dataset

#### **Description**
Create and save prediction surfaces, specifically the empty maps of Taiwan (tif file). Create and save a dataframe containing predictors corresponding to each of the pixels. 

#### **Value**
A dataset and a tif file as predictor surfaces. 



***
### **data_preparation_target_species**
```R
data_preparation_target_species(dir_eBird = here("data", "main_processed", "data_eBird_qualified.csv"),
                                dir_predictors = here("data", "main_processed", "data_eBird_qualified_prodictors.csv"),
                                target_species,
                                path = here("data", "main_processed", paste0("data_eBird_qualified_combined_", target_species, ".csv")))
```
 Argument |  --
--- | --- 
dir_eBird | character, file path of the dataset output from data_preparation_eBird
dir_predictors | character, file path of the dataset output from data_preparation_predictors
target_species | character, species of interest in latin name
path | character, path and name with .csv extension for saving the resulted dataset

#### **Description**
Combine the eBird and predictors dataset for a target species. The output dataset will be used in the following analysis.

#### **Value**
A dataset with eBird observation and the corresponded environmental predictors. The dataset will be ready for the following analysis. 


***
### **modelling_random_forest**
```R
modelling_random_forest(data = data_sub,
                        method = "ranger",
                        cor_threshold = 0.8,
                        max_vars = 15)
```
 Argument |  --
--- | --- 
data | object, subsampled data for variables selection
method | character, method for the random forest, can choose `Boruta` or `ranger`
cor_threshold | numerical, the upper limit of correlation between variables
max_vars | numerical, initial 

#### **Description**
Variables selection out of the 100 environmental variables using random forest. 

#### **Value**
A vector of variables that best describe the variations in the data. 

***
### **modelling_stixel_grouping**
```R
modelling_stixel_grouping(data = data_sub,
                          predictors = predictors,
                          split = 0.8,
                          temporal_resolution = 7,
                          stixel_height = 40)
```
 Argument |  --
--- | --- 
data | object, subsampled data for model fitting
predictors | character, predictors that used in each of the model
split | numerical, the proportion of the data used for training purpose
temporal_resolution | numerical, the temporal shift of the stixel in days
stixel_height | numerical, the temporal scale of the stixel in days

#### **Description**
Re-format the data struction. Split the data into training and test dataset, then further split into stixels.

#### **Value**
A re-structured dataset ready for model fitting.

***
### **modelling_GAM**
```R
modelling_GAM(stixels = stixels, 
              family = "nb", 
              predictors = predictors, 
              workers = 1)
              
```
 Argument |  --
--- | --- 
stixels | object, re-arranged data for model fitting, output from `modelling_stixel_grouping`
family | character, family for the GAM model, options are `nb` or `ziplss`
predictors | character, predictors that used in each of the model
workers | numerical, number of CPUs used for the model fitting task

#### **Description**
Fit the model for each of the stixel

#### **Value**
A new data frame consisting models for each of the  stixel

***
### **modelling_evaluation**
```R
modelling_evaluation(models = models, 
                     family = "nb", 
                     workers = 2)
              
```
 Argument |  --
--- | --- 
models | object, models fitted in `modelling_GAM`
family | character, family for the GAM model, options are `nb` or `ziplss`
workers | numerical, number of CPUs used for the model fitting task

#### **Description**
Evaluate the goodness of fit of the 53 models

#### **Value**
A new data frame consisting the evaluation result

***
### **prediction_maps**
```R
prediction_maps(models = models,
                family = "nb",
                workers = 8,
                duration_minutes = 60,
                effort_distance_km = 1,
                number_observers = 1,
                hour = 6,
                dir_pred_surf = here("data", "main_processed", "prediciton_surface.csv"),
                dir_pred_tif = here("data", "main_processed", "prediction_surface.tif"),
                quantile = 0.1)
              
```
 Argument |  --
--- | --- 
models | object, models fitted in `modelling_GAM`
family | character, family for the GAM model, options are `nb` or `ziplss`
workers | numerical, number of CPUs used for the mapping task
duration_minutes | numerical, to standardize the research effort
effort_distance_km | numerical, to standardize the research effort 
number_observers | numerical, to standardize the research effort
hour | numerical, starting time of the observation to standardize the research effort
dir_pred_surf | character, path and file name of the prediction surface
dir_pred_tif | character, path and file name of the prediction surface in tif
quantile | numerical, the lower limit threshold (in percentage) for plotting the maps


#### **Description**
Produce maps out of the fitted GAM models.

#### **Value**
A list of maps corresponding to each of the fitted model.

***

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change. Please contact the author (sunnyyctseng@gamil.com) for any comments on the project.