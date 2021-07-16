#------------------------------------------------------------------------------
# Type: control script 
# Name: 60_lidar_segementation.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  derives pc tree segments and hulls and the standard metrics

# Data: point cloud, dsm and dtm as derived by 10_CHM_Catalog.R  
# Output: sf polygon object
# Copyright: Chris Reudenbach 2021, GPL (>= 3)
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

library(tidyr)
library(dplyr)
# 2 - define variables
#---------------------
fn = "5-25_MOF_rgb"
## ETRS89 / UTM zone 32N
epsg = 25832
# get viridris color palette
pal<-mapview::mapviewPalette("mapviewTopoColors")
#Saftflusshalbmond
coord = c(xmin,ymin,xmax,ymax)

min_tree_height = 5
dtm  = raster::raster(file.path(envrmt$path_data,"dtm_knnidw_1m.tif")) 
dsm  = raster::raster(file.path(envrmt$path_data,"dsm_p2r_1m.tif"))
las_file=lidR::readLAS("/home/creu/edu/mpg-envinsys-plygrnd/data/lidar/level1/crop_aoimof.las")

crs(dtm) = projection(las_file)
crs(dsm) = projection(las_file)
# 3 - start code 
#-----------------
# calulate the chm
chm=dsm-dtm
# normalize  trees
ht <- lidR::normalize_height(las_file, dtm)

# pc based detection performs poor and is very slow
#st = segment_trees(ht, li2012(speed_up = 6))

# segmentation steps for CHM based algorithms
# there are multiple solution and it is a wide field for sensitvity studies
# a good approach is the estimation ov variable tree heights as a proxy for the number of maxima
# togther with the lmf() function
# hfunc = function(x) { x * 0.07 + 3 }      # from lidR examples
# hfunc = function(x) {7.01565 + 0.45870 * x} # https://doi.org/10.14358/PERS.70.5.589
# hfunc = function(x) { 2.72765 + 0.15628 * x} #DOI: 10.5589/m03-027
# ttops = find_trees(chm, lmf(f, hmin = min_tree_height, shape = "circular"))
# additionally you may use for huge areas the lmfauto() function
# ttops =  find_trees(ht, lmfauto(hmin = min_tree_height))

# the lidR package lidRplugins provides some usefull stuff especially the multichm() funktion
# wich provides a fairly good tree top estimation in heteregonous forests
ttops = find_trees(ht, multichm(res = 1, ws = 7))

# the best segmentation performance is derived by the dalponte algorithm (as far as lidR is used)
st = segment_trees(ht, dalponte2016(chm, treetops=ttops))

# have a look
# x = plot(st,color = "treeID")
# add_treetops3d(x, ttops)

# no filtering for non tree ids and deriving statistics and the projected hull 
trees   = lidR::filter_poi(st, !is.na(treeID))
hulls = lidR::delineate_crowns(trees, type = "concave", concavity = 2,func= .stdmetrics)

# save it to a common  file format
hulls_sf = as(hulls,"sf")
st_write(hulls_sf,file.path(envrmt$path_level1,"sapflow_tree_segments_multichm_dalponte2016.gpkg"))
lidR::writeLAS(trees,file.path(envrmt$path_level1,"sapflow_tree_segments_multichm_dalponte2016.las"))
