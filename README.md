# RADI_Taiwan_2020

RADI_Taiwan is a project aiming to create avian species distribution maps using eBird data. The method was adapted from Status and Trends products by Cornell Lab of Ornithology (Fink et al., 2020).

## Usage



## File structure



## Main References 

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

## Installation

Use the package manager [pip](https://pip.pypa.io/en/stable/) to install foobar.

```bash
pip install foobar
```

## Usage

```python
import foobar

foobar.pluralize('word') # returns 'words'
foobar.pluralize('goose') # returns 'geese'
foobar.singularize('phenomena') # returns 'phenomenon'
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)