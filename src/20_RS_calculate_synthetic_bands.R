#------------------------------------------------------------------------------
# Type: control script 
# Name: 20_RS_calculate_synthetic_bands.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  - calculate on base of RGB image(s)
#               - RGB Indices
#               - structural channels
#               - statistical derivations

# Data:         corrected RGB image of AOI 
# Output:       comprehensive image stack of useful bands 
# Details:      it is crucial to get find an adequate kernel size wth respect to 
#               the main target objects size. This will increase the model results 
#               considerably. for tree crowns 20 is approx. fair
# Copyright: Chris Reudenbach, Thomas Nauss 2017,2020, GPL (>= 3)
# git clone https://github.com/GeoMOER-Students-Space/msc-phygeo-class-of-2020-creu.git
#------------------------------------------------------------------------------
rm(list = ls()) 

if(!exists("envrmt")){
  # 0 - load packages
  #-----------------------------
  require(envimaR)
  
  # 1 - source files
  #-----------------
  source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd", alt_env_id = "COMPUTERNAME", alt_env_value = "PCRZP", alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                   "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))
}

# 2 - define variables
#-----------------------------
# link to the GI packages - adapt it to your needs
otb  = link2GI::linkOTB(searchLocation = "/usr/bin/")
gdal  = link2GI::linkGDAL()
# clean run/tmp dir
unlink(paste0(envrmt$path_tmp,"*"), force = TRUE)


# 3 - start code 
#-----------------
# calculation of synthetic bands using the make_syn_bands function which is extracted from the uavRst package

res <- make_syn_bands(calculateBands    = T,
                      prefixIdx         = "course2020_",
                      prefixRun         = "course2020_" ,
                      suffixTrainImg    = "MOF_area" ,
                      rgbi              = T,
                      indices           =  c("HUE","VVI","TGI","RI","SCI","BI","CI","SI","HI","VARI","NDTI","NGRDI","GRVI","GLI","GLAI","SAT","SHP"),
                      channels          = "PCA_RGB", 
                      hara              = F,
                      haraType          = c("simple"),
                      stat              = T,
                      edge              = T,
                      morpho            = T,
                      pardem            = F,
                      kernel            = seq(5,25,5),
                      currentDataFolder = envrmt$path_aerial,
                      currentIdxFolder  = envrmt$path_aerial,
#                      sagaLinks = saga,
                      otbLinks = otb,
                      gdalLinks = gdal,
                      path_run = envrmt$path_tmp)


cat(getCrayon()[[3]](":::: finished ",scriptName::current_filename(),"\n"))

