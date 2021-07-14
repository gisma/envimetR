#------------------------------------------------------------------------------
# Type: control script 
# Name: 20_segmentation_Catalog.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  calculates a comprehensive set of tree segmentations based on the CHM data set
# Data: CHM raster file as derived by 10_CHM_Catalog.R 
# Output: Segmentation layers
# Copyright: Chris Reudenbach, Thomas Nauss 2017,2020, GPL (>= 3)
#------------------------------------------------------------------------------

## clean your environment
rm(list=ls()) 

# 0 - load packages
#-----------------------------


## dealing with the crs warnings is cumbersome and complex
## you may reduce the warnings with uncommenting  the following line
## for a deeper  however rarely less confusing understanding have a look at:
## https://rgdal.r-forge.r-project.org/articles/CRS_projections_transformations.html
## https://www.r-spatial.org/r/2020/03/17/wkt.html
rgdal::set_thin_PROJ6_warnings(TRUE)


# 1 - source files
#-----------------
source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd",
                                          alt_env_id = "COMPUTERNAME",
                                          alt_env_value = "PCRZP",
                                          alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                 "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))


# 2 - define variables
#---------------------

## ETRS89 / UTM zone 32N
epsg = 25832

dtm  = raster::raster(file.path(envrmt$path_data,"dtm_knnidw_1m.tif")) 
csm  = raster::raster(file.path(envrmt$path_data,"dsm_p2r_1m.tif"))
crop_aoimof_ctg=readRDS(file.path(envrmt$path_data,"crop_aoimof_ctg.rds"))
opt_output_files(crop_aoimof_ctg) <- paste0(envrmt$path_tmp,"{ID}_HULL_{XCENTER}_{YCENTER}")
opt_chunk_buffer(crop_aoimof_ctg) <- 40
th = 2

# get viridris color palette
pal<-mapview::mapviewPalette("mapviewTopoColors")

# 3 - start code 
#-----------------

out <- catalog_apply(crop_aoimof_ctg, tree_ws_hull, dsm = csm, dtm = dtm, th = 2, tol=0.2,ext=3)
mapview(st_read(out))

saveRDS(out,file= file.path(envrmt$path_level1,"crop_aoimof_tree_segments.rds"))

# 4 - visualize 
# -------------------
metrics = tree_metrics(st_read(out), .stdtreemetrics)
