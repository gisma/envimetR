#------------------------------------------------------------------------------
# Type: control script 
# Name: 10_GI_CHM.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  script creates a canopy height model from generic Lidar 
#              las data using the lidR package. In addition the script cuts the area to 
#              a defined extent using the lidR catalog concept.
#              Furthermore the data is tiled into a handy format even for poor memory 
#              and a canopy height model is calculated
# Data: regular las LiDAR data sets 
# Output: Canopy heightmodel RDS file of the resulting catalog
# Copyright: Chris Reudenbach, Thomas Nauss 2017,2020, GPL (>= 3)
#------------------------------------------------------------------------------

## clean your environment
rm(list = ls()) 
gc()

# 0 - load packages
#-----------------------------


# 1 - source files
#-----------------
source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd",
                                          alt_env_id = "COMPUTERNAME",
                                          alt_env_value = "PCRZP",
                                          alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                 "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))
#unlink(envrmt$path_tmp)

# 2 - define variables
#---------------------

# switch if lasclip is called
set.seed(1000)
#Saftflusshalbmond
coord = c(xmin,ymin,xmax,ymax)


# 3 - start code 
#-----------------
las_file=lidR::readLAS(paste0(envrmt$path_lidar_level0,"MOF_lidar_2018.las"))
las_file = lidR::clip_rectangle(las_file, 
                                       xleft = coord[[1]], 
                                       ybottom = coord[[2]], 
                                       xright = coord[[3]], 
                                       ytop = coord[[4]])

# the fastest and simplest algorithm to interpolate a surface is given with p2r()
# the available options are  p2r, dsmtin, pitfree
dsm_p2r_1m = lidR::grid_canopy(las_file, res = 1, algorithm = pitfree())

raster::writeRaster(dsm_p2r_1m,file.path(envrmt$path_data,"dsm_p2r_1m.tif"),overwrite=TRUE) 
plot(dsm_p2r_1m)              

# now we calculate a digital terrain model by interpolating the ground points 
# and creates a rasterized digital terrain model. The algorithm uses the points 
# classified as "ground" and "water (Classification = 2 and 9 according to LAS file format 
# available algorithms are  knnidw, tin, and kriging
dtm_knnidw_1m <- grid_terrain(las_file, res=1, algorithm = knnidw(k = 15L, p = 2))
raster::writeRaster(dtm_knnidw_1m,file.path(envrmt$path_data,"dtm_knnidw_1m.tif"),overwrite=TRUE) 
saveRDS(crop_aoimof_ctg,file.path(envrmt$path_data,"crop_aoimof_ctg.rds"))
mapview(dtm_knnidw_1m)

# we remove the elevation of the surface from the catalog data and create a new catalog
crop_aoimof_chm <- lidR::normalize_height(las_file,dtm_knnidw_1m)
saveRDS(crop_aoimof_chm, file= file.path(envrmt$path_level1,"crop_aoimof_chm.rds"))


# Now create a CHM based on the normalized data and a CHM with the dsmtin() algorithm
# calculate a chm raster with dsmtin()
chm_dsmtin_1m = lidR::grid_canopy(crop_aoimof_chm, res=1.0, dsmtin())
raster::writeRaster(chm_dsmtin_1m,file.path(envrmt$path_data,"chm_dsmtin_1m.tif"),overwrite=TRUE) 
plot(chm_dsmtin_1m)

# 4 - visualize 
# -------------------


## call mapview with some additional arguments
mapview(chm_dsmtin_1m,
        map.types = "Esri.WorldImagery",  
        legend=TRUE, 
        layer.name = "canopy height model",
        col = pal(256),
        alpha.regions = 0.65)

