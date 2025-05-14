# Overview

Main sections:
- [Description of Folders](#description-of-folders)
- [KI-67 Analysis Extension](#ki-67-analysis-extension)
- [Notes](#notes)

Project used to store files relevant for analysis of control tissue in Ki-67 slides, as well as all code required to automate this process with an extension.

Author Matthew Litwiller

Last update April 29 2025

Recommended QuPath version: [QuPath-0.6.0-rc1](https://github.com/qupath/qupath/releases/tag/v0.6.0-rc1) - launching console version will help with diagnosing problems. 

# Description of Folders

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
Contains instanseg models required for running instanseg. For the Ki-67 project, only the brightfield_nuclei model should be used. This can also be found online. See GPU setup for InstanSeg as it is required for the extension [below](#setup).

## predictions
Contains predictions of tissue regions for various slides. 

Note: a groovy script exists to import all predictions and can be used in the QuPath UI or the produce_data_pipeline.sh pipeline: import_geojson_annotations.groovy

## cell_data
Somewhat unorganized folder with cell data & data analysis using R. Rstudio 2024.09.0+375 was used for handling all data and generating all graphs. 

Sub-folders of interest:
- GlenDilution: used for glen dilution series
- AllSLides2_NewModels: DAB & Positivity visualizations for entire dataset


# KI-67 Analysis Extension

Ki-67 analysis can be performed project-wide using the extension developed in this repository. 

## Setup:
- Required files & folders:
    ```
    - groovy_scripts folder
    - python_scripts folder
    - models folder
    - ki67-assessment-0.1.0-SNAPSHOT-all.jar extension file
    - requirements.txt file
    - QuPath-0.6.0-rc1 (console).exe launcher
    Note: .exe file not included in this repo, this is installed with QuPath directly
    ```
- Anaconda must be installed as a python environment will be created within the extension to run the computer vision libraries required for predicting cell regions. [Download Anaconda here](https://www.anaconda.com/download)
- Instanseg extension must be installed and setup for using GPU. [Standard download here](https://github.com/instanseg/instanseg). Steps for enabling GPU on QuPath v6-rc1 (From Ajay Rajaram & Dr. Rolf Harkes):
```
  1. To get the gpu option for InstaSeg (and WSInfer) working, uninstall your current CUDA (find all CUDA on Add/Remove programs and uninstall)
  2. Restart machine
  3. On reboot, delete the directory C:\Program Files\NVIDIA GPU Computing Toolkit
  4. Download CUDA 12.1 (see resources below) 
  5. Similarly, download the recent cuDNN for CUDA 12.1 (see resources below)
  6. Install CUDA 12.1; Select custom install and uncheck the graphic drivers (else it will overwrite these with older versions)
  7. Unzip contents of cuDNN into the respective folders in C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1
  8. You don't need conda or mamba; Just Python 3.10 or above is enough. So, you can uninstall Anaconda/Mamba, and retain Python or install Python 3.10 and above. I believe for Linux, conda will be a better option
  9. When done, open a command prompt, and install Pytorch 2.3.1 for CUDA 12.1 by entering the following on the command prompt: pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121
  10. For Linux, it can be installed using conda: conda install pytorch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 pytorch-cuda=12.1 -c pytorch -c nvidia (use the same to download PyTorch on Windows 11 if you have conda instead Python)
  11. Now run QuPath v0.6.0-rc1 and click on Extensions>Deep Java LIbrary>Manage DJL Engine
  12. In the DJL engines window, click on Check / Download under PyTorch, and you should see 2.3.1-cu121-win-x86_64 downloaded in the Path.
  13. If all the above steps are done right, you will be able to select GPU in the InstanSeg window!
```
Resources from steps 4-5 can be found here:

Windows 11 CUDA 12.1 [here](https://developer.nvidia.com/cuda-12-1-0-download-archive?target_os=Windows&target_arch=x86_64&target_version=11&target_type=exe_local)

Linux CUDA 12.1 [here](https://can01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fdeveloper.nvidia.com%2Fcuda-12-1-0-download-archive%3Ftarget_os%3DLinux%26target_arch%3Dx86_64%26Distribution%3DUbuntu%26target_version%3D22.04&data=05%7C02%7Cmatthew.litwiller%40mail.mcgill.ca%7C6a293d555c854543b0c208dcd7fd710e%7Ccd31967152e74a68afa9fcf8f89f09ea%7C0%7C0%7C638622730752864248%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C0%7C%7C%7C&sdata=FF6gnSwFzh09HeHKsCSrhKCTfKKqDv%2FSwQ3GZNH%2BW70%3D&reserved=0)

Windows cuDNN for CUDA 12.1 [here](https://can01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fdeveloper.nvidia.com%2Fdownloads%2Fcompute%2Fcudnn%2Fsecure%2F8.9.7%2Flocal_installers%2F12.x%2Fcudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip%2F&data=05%7C02%7Cmatthew.litwiller%40mail.mcgill.ca%7C6a293d555c854543b0c208dcd7fd710e%7Ccd31967152e74a68afa9fcf8f89f09ea%7C0%7C0%7C638622730752879932%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C0%7C%7C%7C&sdata=rr7%2Beai1dBErCKplHq999ymrlWzY5i8IlxpGW47GlN4%3D&reserved=0)

Ubuntu 22.04 cuDNN for CUDA 12.1 [here](https://can01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fdeveloper.nvidia.com%2Fdownloads%2Fcompute%2Fcudnn%2Fsecure%2F8.9.7%2Flocal_installers%2F12.x%2Fcudnn-local-repo-ubuntu2204-8.9.7.29_1.0-1_amd64.deb%2F&data=05%7C02%7Cmatthew.litwiller%40mail.mcgill.ca%7C6a293d555c854543b0c208dcd7fd710e%7Ccd31967152e74a68afa9fcf8f89f09ea%7C0%7C0%7C638622730752895830%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C0%7C%7C%7C&sdata=m8lYblJaTO5sy7AzmXihknx%2Bp1buUwxcive64%2F8NeMU%3D&reserved=0)

## qp_extension 
Contains the jar file for running the KI67 extension. This should be placed within the QuPath extension folder. To locate the extension folder in QuPath, navigate to ```Extensions > Manage Extensions > Open extension directory```.
The ki67 extension .jar file should be placed within this folder.

## Extension workflow
Once all setup is complete, the extension can be accessed via ```Extensions > Ki-67 Assessment > Run assessment```. The extension will run on all slides in a project, and a project should be open before running. Once the window is open here is an overview of the workflow:

1. Extension Setup: Set file and folder destinations (& optionally save for later use)
2. Producing YOLO Predictions: Input downsample to reduce size of images while maintaining as much detail as possible. This downsample will be used for both ```convert WSI to JPG``` and ```Perform YOLO predictions``` steps and should not vary from one run to another unless both steps are recomputed in the same run.
3. Post-Processing:
```
- Filtering predictions to keep only predictions within tonsil and appendix regions
- Combining predictions
- Filling holes in predictions
- Ensuring dark and light zones do not overlap
- Removing small predictions
- Ensuring LZ/DZ exist only within GC
- Ensuring no mantle region overlaps with a GC
```
4. Stain Vectors: To customize stain vectors for stains that differ from stains used at the GLEN hospital during development of the extension. Tip: use the default QuPath tool ```Analyze > Estimate Stain Vector``` can be used to approximate a new stain vector, but may not capture the full optical density range. The stain vectors set here will have a direct effect on the DAB values of the detected cells. All vectors must be normalized.
5. InstanSeg: Recommended to only run for light zone (LZ), dark zone (DZ) & germinal center (GC) regions as mantle expression is difficult to quantify and subject to a high degree of variability. The analysis results do not consider mantle regions for its assessment.
6. Cell Classification: Classify cells into positive and negative based on a single threshold of the DAB values (0.15 recommended)
7. Results: Output analysis results in an annotation for each slide. The analysis will, among others, check that the rate of positive cells within the desired regions is above the inputted values. Additionally, it checks for blurriness based on the density of detected cells over the annotation areas.
8. Export for Power BI: Used to export analysis results in a csv file for visualizations (e.g. with Power BI). Useful for quality assessment over time in a Levey-Jennings graph or other. 

# Notes
- All code was developed on windows using Nvidia GPUs with cuda cores
- Extension code was developed using [jdk21](https://adoptium.net/) but works with other versions, such as jdk17. 
- For non-extension usage: paths were setup for my local machine and will need to be reworked.
- For extension usage, the user will be prompted to select the location of all files except the extension .jar file and remaining paths are handled by passing arguments to the scripts. Paths should not have spaces
- For non-extension usage, I did not document my own conda environment setup and this will require some setup.
- For extension usage, a virtual environment can be used to run all python operations by installing all libraries in ```requirements.txt```, provided anaconda is setup on the machine. There is a GUI for this in the extension. 
