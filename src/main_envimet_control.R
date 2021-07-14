#------------------------------------------------------------------------------
# Type: control script
# Name: envimet_control.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  - control file for the RS course workflow
#               - destripe, merge and clip all images
#               - calculate synthetic bands
#               - extract training data
#               - check and clean training data
#               - run classification

#
# Data: regular authority provided airborne RGB imagery, supervised trainingdata
# Output: merged, clipped and corrected image of AOI, stack of synthetic bands,
#         raw training dataframe, corrected traiing data frame,
#         rf llo ffs classifcation model, prediction
# Copyright: Chris Reudenbach, Thomas Nauss 2017,2021, GPL (>= 3)
# git clone https://github.com/GeoMOER-Students-Space/.git
#------------------------------------------------------------------------------

## clean your environment
##
rm(list=ls())

library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))


# data preprocessing
#-----------------
## data preprocessing step 1 destriping/merging and corpping the aerial images
# source(file.path(rootDir,"/src/10_preprocess_RGB.R"))

## data preprocessing step 2 calculate synthetic images
# source(file.path(rootDir,"/src/20_calculate_synthetic_bands.R"))

## data  preprocessing step 3  extract the raw training data
# source(file.path(rootDir,"/src/30_extract_training_data_PCA.R"))

#------------------------------------------------------------------------------------------
# Finish preprocessing of the level 0 basic data
#----------------------------------------------------------------------------------------

##  step 4 cleaning the training data for a random forest model training
#source(file.path(rootDir,"/src/40_RS_high_resolution data_model_training_rev.R"))

# modeling and prediction
## step 5 leave location out forward feature selection (llo-ffs)  random forest model training and prediction
source(file.path(rootDir,"/src/50_chm.R"))

# modeling and prediction
## step 5 leave location out forward feature selection (llo-ffs)  random forest model training and prediction
source(file.path(rootDir,"/src/60_lidar_segmentation.R.R"))

# modeling and prediction
## step 5 leave location out forward feature selection (llo-ffs)  random forest model training and prediction
source(file.path(rootDir,"/src/70_prepare_envimet_simple_plants.R"))

# modeling and prediction
## step 5 leave location out forward feature selection (llo-ffs)  random forest model training and prediction
source(file.path(rootDir,"/src/80_tree_cluster_analysis.R"))
