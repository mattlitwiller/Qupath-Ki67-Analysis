Project used to store files relevant for analysis of control tissue in Ki-67 slides.

Author Matthew Litwiller

Last update Feb 5 2025

# Description of folders

## groovy_scripts
Used to store all groovy scripts relevant to the project, both useful for model generation and for post-processing & outputting results in QuPath. All groovy scripts can be used from the QuPath CLI. 

produce_data_pipeline.sh can be used to automate a string of CLI commands to run in batch more efficiently than the QuPath UI allows, while also helping automate the process. 

## python_scripts
Used to prep data for yolo model training and to train the model. Yolo training steps are outlined in prep_data.sh. Once data is prepped, a model can be trained using the yolo_model.py and predictions can be run using pbi_yolo.py. predict.sh can also be used to run pbi_yolo.py and to store parameters. 

Notes: 
- yolo11n-seg.pt is used to train custom yolo models - it is not a trained model for detecting Ki-67 tissue structures.
- A conda environment will be necessary to run steps for training models and predicting with models. Training especially becomes useful on the remote server as it can be time consuming.

## models
Contains 3 custom trained yolov11 models to detect germinal centers (GC) + mantle regions, light zone (LZ) + dark zone(DZ) regions, and tonsil + appendix tissues. 

## instanseg
Contains instanseg models required for running instanseg. For the Ki-67 project, only the brightfield_nuclei model should be used. This can also be found online.

## predictions
Contains predictions of tissue regions for various slides. 

Note: a groovy script exists to import all predictions and can be used in the QuPath UI or the produce_data_pipeline.sh pipeline: import_geojson_annotations.groovy

## cell_data
Somewhat unorganized folder with cell data & data analysis using R. Rstudio 2024.09.0+375 was used for handling all data and generating all graphs. 

Sub-folders of interest:
- GlenDilution: used for glen dilution series
- AllSLides2_NewModels: DAB & Positivity visualizations for entire dataset


### Overall Notes
- Paths are setup for my local machine and will need to be reworked
- I did not document my own conda environment setup and this will likely require some setup
