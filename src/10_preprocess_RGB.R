#------------------------------------------------------------------------------
# Type: control script
# Name: 10_RS_preprocess_RGB.R
# Version 0.2
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  - destripe the white areas of the airborne RGB images
#               - merge all images in a folder to one image
#               - clip the image to a defined (NOTE by default as defined in setup)
#                 the "sap flow half moon" extent is used
#
# changelog 0.2:- merge and correction code has moved to functions
#               - It is tested now if the files exist
#                 to jump over the time consuming process of
#                 correcting merging, projecting and cropping the data
#               - all output filenames are defined by variables
#
# Data: regular authority provided airborne RGB imagery
# Output: merged, clipped and corrected image of AOI is written to filesystem
#         and added to the environment (aoi_RGB)
# Copyright: Thomas Nauss, Chris Reudenbach 2017,2021, GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

# 0 - load packages
#-----------------------------
library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))

set.seed(123)


# 2 - define variables
#---------------------

# create deprecated proj4 projection string
crs_rgb=sp::CRS("+init=epsg:25832")


# modify cropping extent according to example training data as provided by:
# https://github.com/HannaMeyer/OpenGeoHub_2019/blob/master/practice/data/
# Download github archive
url<-"https://github.com/HannaMeyer/OpenGeoHub_2019/archive/master.zip"
# extract the necessary data
if(!file.exists(paste0(envrmt$path_auxdata,basename(url)))) {
downloader::download(url,paste0(envrmt$path_auxdata,basename(url)))
# extract relevant files
unzip(paste0(envrmt$path_auxdata,basename(url)),
      files = unzip(paste0(envrmt$path_auxdata,basename(url)), list=TRUE)$Name[11:18],
      exdir=envrmt$path_auxdata,
      overwrite = TRUE, junkpaths = T)
}
# read and project the training data polygons
trainSites <- sf::read_sf(file.path(envrmt$path_auxdata,"trainingSites.shp"))
trainSites <- sf::st_transform(trainSites,crs=crs_rgb)

# set the cropping extent
ext <- extent(trainSites)

# define file name and location
mergename=file.path(envrmt$path_aerial,"MOF_rgb_merged.tif")
outname=file.path(envrmt$path_aerial,"MOF_rgb.tif")

# start processing
#-----------------------------------------

##-- if necessary correcting the white stripes
# get list of files
# NOTE adapt the wildcard in the glob2rx call if necessary
tif_files = list.files(envrmt$path_aerial_org, pattern = glob2rx("4*.tif"), full.names = TRUE)
destripe_rgb(files = tif_files,
             envrmt = envrmt)


##-- if the merge file exist just load it for cropping
if(length(mergename)>0){
  merged_mof = raster::stack(mergename)
} else {

##-- merge and re-project the single images
# NOTE adapt the wildcard in the glob2rx call if necessary
  tif_files = list.files(envrmt$path_aerial_org, pattern = glob2rx("4*.tif"), full.names = TRUE)
  merged_mof = merge_rgb(files = tif_files,
                         output = mergename,
                         cropoutput=outname,
                         proj4 = crs_rgb,
                         ext = ext)
}

# cropping it
if(!file.exists(outname)){
cat("crop AOI\n")
aoi_RGB  =  crop(merged_mof, ext)

# save the croped raster
raster::writeRaster(aoi_RGB ,
                    outname,
                    overwrite=TRUE,
                    progress="text")
}

cat(getCrayon()[[3]](":::: finished ",scriptName::current_filename(),"\n"))
cat(getCrayon()[[1]](":::: merged file is saved at: ",mergename,"\n"))
cat(getCrayon()[[1]](":::: cropped file is saved at: ",outname ,"\n"))
