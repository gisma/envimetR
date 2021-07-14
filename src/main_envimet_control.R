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

# derive canopy heightmodel CHM
## step 5 the calculation of a high quality CHM is performed using lidR
source(file.path(rootDir,"/src/50_chm.R"))

# segemntation
## step 6 a almost standard segementation using the point cloud and the chm is performed
source(file.path(rootDir,"/src/60_lidar_segmentation.R.R"))

# Retrieval aof Sentinel 2 data
## step 7 to calculate LAI and Albdo some Sentinel processing is done
source(file.path(rootDir,"/src/70_retrieve_sentinel_stuff.R"))

# Preprocessing of the simple plants data base
## step 8  quite some calculatins and extraction procedures to obtain unified values fpor the envimet plant data base
source(file.path(rootDir,"/src/80_prepare_envimet_simple_plants.R"))

# Cluster Analysis of the accumulated tree variables
## step 9  identfy synthetic tree types
source(file.path(rootDir,"/src/90_tree_cluster_analysis.R"))
