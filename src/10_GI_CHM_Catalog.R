#------------------------------------------------------------------------------
# Type: control script 
# Name: 10_CHM_Catalog.R
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

library("future")

options(future.rng.onMisue = "ignore")

# 1 - source files
#-----------------
source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd",
                                          alt_env_id = "COMPUTERNAME",
                                          alt_env_value = "PCRZP",
                                          alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                 "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))
unlink(envrmt$path_tmp)

# 2 - define variables
#---------------------

# switch if lasclip is called
lasclip = FALSE
plott=FALSE
set.seed(1000)
#Saftflusshalbmond
coord = c(xmin,ymin,xmax,ymax)

# setup future for parallel
future::plan(multisession, workers = 4L,  future.seed = TRUE)
set_lidr_threads(4L)


# 3 - start code 
#-----------------

#---- if not clipped yet
if (lasclip){
  ctg <- lidR::readLAScatalog(envrmt$path_lidar_level0)
  projection(ctg) <-25832
  lidR::opt_chunk_size(ctg) = 400

  lidR::opt_chunk_buffer(ctg) <- 20
  lidR::opt_output_files(ctg) <- paste0(envrmt$path_tmp,"{ID}_cut") # add output filname template
  ctg@output_options$drivers$Raster$param$overwrite <- TRUE
  
  crop_aoimof_ctg = lidR::clip_rectangle(ctg, 
                                         xleft = coord[[1]], 
                                         ybottom = coord[[2]], 
                                         xright = coord[[3]], 
                                         ytop = coord[[4]])
  projection(crop_aoimof_ctg) <-25832
  lidR::opt_chunk_size(crop_aoimof_ctg) = 650
  lidR::opt_chunk_buffer(crop_aoimof_ctg) <- 50
  saveRDS(crop_aoimof_ctg,file= file.path(envrmt$path_level1,"crop_aoimof.rds"))
  
} else   crop_aoimof_ctg = readRDS(file= file.path(envrmt$path_level1,"crop_aoimof.rds"))

#---- assuming that the "crop_aoimof_ctg" catalog is stored in envrmt$path_lidar_level0 

# the fastest and simplest algorithm to interpolate a surface is given with p2r()
# the available options are  p2r, dsmtin, pitfree
lidR::opt_output_files(crop_aoimof_ctg) <- paste0(envrmt$path_tmp,"{ID}_dsm_p2r_1m") # add output filname template
dsm_p2r_1m = lidR::grid_canopy(crop_aoimof_ctg, res = 1, algorithm = pitfree())
raster::writeRaster(dsm_p2r_1m,file.path(envrmt$path_data,"dsm_p2r_1m.tif"),overwrite=TRUE) 
if (plott) plot(dsm_p2r_1m)              

# now we calculate a digital terrain model by interpolating the ground points 
# and creates a rasterized digital terrain model. The algorithm uses the points 
# classified as "ground" and "water (Classification = 2 and 9 according to LAS file format 
# available algorithms are  knnidw, tin, and kriging
lidR::opt_output_files(crop_aoimof_ctg) <- paste0(envrmt$path_tmp,"{ID}_dtm_knnidw_1m") # add output filname template
dtm_knnidw_1m <- grid_terrain(crop_aoimof_ctg, res=1, algorithm = knnidw(k = 15L, p = 2))
raster::writeRaster(dtm_knnidw_1m,file.path(envrmt$path_data,"dtm_knnidw_1m.tif"),overwrite=TRUE) 
saveRDS(crop_aoimof_ctg,file.path(envrmt$path_data,"crop_aoimof_ctg.rds"))
if (plott) mapview(dtm_knnidw_1m)
if (plott) plot(crop_aoimof_ctg, mapview = TRUE)

# we remove the elevation of the surface from the catalog data and create a new catalog
lidR::opt_output_files(crop_aoimof_ctg) <- paste0(envrmt$path_tmp,"{ID}_aoimof_chm") # add output filname template
crop_aoimof_chm <- lidR::normalize_height(crop_aoimof_ctg,dtm_knnidw_1m)
if (plott) plot(crop_aoimof_chm, mapview = TRUE)

# if you want to save this catalog  an reread it  you need 
# to uncomment the following lines
saveRDS(crop_aoimof_chm, file= file.path(envrmt$path_level1,"crop_aoimof_chm.rds"))
#- mof100_ctg_chm<-readRDS(file.path(envrmt$path_level1,"mof100_ctg_chm.rds"))


# Now create a CHM based on the normalized data and a CHM with the dsmtin() algorithm
lidR::opt_output_files(crop_aoimof_chm) <- paste0(envrmt$path_tmp,"{ID}_chm_dsmtin") # add output filname templat
# calculate a chm raster with dsmtin()
chm_dsmtin_1m = lidR::grid_canopy(crop_aoimof_chm, res=1.0, dsmtin())
raster::writeRaster(chm_dsmtin_1m,file.path(envrmt$path_data,"chm_dsmtin_1m.tif"),overwrite=TRUE) 


# 4 - visualize 
# -------------------

## standard plot command

if (plott){
plot(chm_dsmtin_1m)

## call mapview with some additional arguments
mapview(chm_dsmtin_1m,
        map.types = "Esri.WorldImagery",  
        legend=TRUE, 
        layer.name = "canopy height model",
        col = pal(256),
        alpha.regions = 0.65)

}