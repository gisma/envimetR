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
# get viridris color palette
pal<-mapview::mapviewPalette("mapviewTopoColors")
#Saftflusshalbmond
coord = c(xmin,ymin,xmax,ymax)

dtm  = raster::raster(file.path(envrmt$path_data,"dtm_knnidw_1m.tif")) 
csm  = raster::raster(file.path(envrmt$path_data,"dsm_p2r_1m.tif"))
las_file=lidR::readLAS(paste0(envrmt$path_lidar_level0,"MOF_lidar_2018.las"))
las_file = lidR::clip_rectangle(las_file, 
                                xleft = coord[[1]], 
                                ybottom = coord[[2]], 
                                xright = coord[[3]], 
                                ytop = coord[[4]])
th = 2
tol=0.2
ex=3


# 3 - start code 
#-----------------

chm=csm-dtm
ht <- lidR::normalize_height(las_file, dtm)
f <- function(x) { x * 0.07 + 3 }
ttops <- find_trees(chm, lmf(f,hmin = 8,shape = "circular"))
ht_ws = segment_trees(las, dalponte2016(chm, ttops))
trs <- lidR::filter_poi(ht_ws, !is.na(treeID))
hulls <- lidR::delineate_crowns(trs, type = "concave", concavity = 2, func = .stdmetrics)
hulls = as(hulls,"sf")
saveRDS(hulls,file= file.path(envrmt$path_level1,"aoimof_tree_segments.rds"))
st_write(hullsfile= file.path(envrmt$path_level1,"aoimof_tree_segments.shp"))
# 4 - visualize 
# -------------------
mapview(hulls,zclo="")
