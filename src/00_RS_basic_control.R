#------------------------------------------------------------------------------
# Type: control script 
# Name: 00_RS_basic_control.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  - control file for the RS course workflow
#               - destripe, merge and clip all images
#               - calculate synthetic bands
#               - extract training data
#               - check and clean training data
#               - run classification
#               
# Workflow
# (00) 10_RS_preprocess_RGB.R destripe, merge and clip all RGB aerial images
# (01) 20_RS_calculate_synthetic_bands.R calculation of spectral indices, basic spatial statistics and textures 
# (02) 30_RS_extract_training_df_RS.R extracting of training values over all channels according to training data\cr\cr
# (03) 40_RS_prepare_training_df.R clean training data according to used classificator\cr\cr
# (04) 50_RS_LLO_rf_classification.R training and prediction using random forest and the forward feature selection method 

#              
# Data: regular authority provided airborne RGB imagery, supervised trainingdata 
# Output: merged, clipped and corrected image of AOI, stack of synthetic bands, 
#         raw training dataframe, corrected traiing data frame, 
#         rf llo ffs classifcation model, prediction
# Copyright: Chris Reudenbach, Thomas Nauss 2017,2021, GPL (>= 3)
# git clone https://github.com/GeoMOER-Students-Space/msc-phygeo-class-of-2020-creu.git
#------------------------------------------------------------------------------

## clean your environment
## 
rm(list=ls()) 


# 0 - load additional packages
#-----------------------------
require(envimaR)

# 1 - source files
#-----------------
  
source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd",
                                          alt_env_id = "COMPUTERNAME",
                                          alt_env_value = "PCRZP",
                                          alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                 "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))



# data preprocessing 
#-----------------
## data preprocessing step 1 destriping/merging and corpping the aerial images
#source(file.path(rootDir,"msc-phygeo-class-of-2020-creu/src/10_RS_preprocess_RGB.R"))

## data preprocessing step 2 calculate synthetic images
source(file.path(rootDir,"msc-phygeo-class-of-2020-creu/src/20_RS_calculate_synthetic_bands.R"))

## data  preprocessing step 3  extract the raw training data
source(file.path(rootDir,"msc-phygeo-class-of-2020-creu/src/30_RS_extract_training_df.R"))

#------------------------------------------------------------------------------------------
# Finish preprocessing of the level 0 basic data
#----------------------------------------------------------------------------------------

##  step 4 cleaning the training data for a random forest model training
source(file.path(rootDir,"msc-phygeo-class-of-2020-creu/src/40_RS_prepare_training_df.R"))

# modeling and prediction
## step 5 leave location out forward feature selection (llo-ffs)  random forest model training and prediction
source(file.path(rootDir,"msc-phygeo-class-of-2020-creu/src/50_RS_LLO_rf_classification_RS.R"))
