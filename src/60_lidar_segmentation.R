#------------------------------------------------------------------------------
# Type: control script
# Name: enviMet_simple_plants.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  derives pc tree segments and hulls and the standard metrics

# Data: point cloud, dsm and dtm as derived by 10_CHM_Catalog.R
# Output: sf polygon object
# Copyright: Chris Reudenbach 2021, GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))

# 2 - define variables
#---------------------
fn = "5-25_MOF_rgb"


min_tree_height = 5
dtm  = raster::raster(file.path(envrmt$path_data,"dtm_knnidw_1m.tif"))
dsm  = raster::raster(file.path(envrmt$path_data,"dsm_p2r_1m.tif"))
ht = readRDS(file.path(envrmt$path_level1,"crop_aoimof_chm.rds"))
#
proj4string=CRS("+init=epsg:25832")
st_crs(ht) <- epsg
#las_file=lidR::readLAS("/home/creu/edu/mpg-envinsys-plygrnd/data/lidar/level1/crop_aoimof.las")
#las_file=lidR::readLAS(paste0(envrmt$path_lidar_level0,"MOF_lidar_2018.las"))
#ht = lidR::clip_rectangle(las_file, xleft = xmin, ybottom = xmax, xright = ymin, ytop = ymax)

raster::crs(dtm) = projection(ht)
raster::crs(dsm) = projection(ht)
# 3 - start code
#-----------------
# calulate the chm
chm=dsm-dtm
raster::crs(chm) =  paste0("epsg:",epsg)
terra::writeRaster(chm,file.path(envrmt$path_level1,"chm_1m.tif"),overwrite=TRUE)
#chm = terra::crop(terra::rast(file.path(envrmt$path_level1,"chm_1m.tif")),ext(xmin, xmax,  ymin,  ymax))
# normalize  trees
#ht <- lidR::normalize_height(las_file, dtm)

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
ttops = find_trees(ht, lidRplugins::multichm(res = 1, ws = 7))
sp::proj4string(ttops) <- proj4string
saveRDS(ttops,file.path(envrmt$path_level1,"ttops.rds"))
ttops=readRDS(file.path(envrmt$path_level1,"ttops.rds"))
# the best segmentation performance is derived by the dalponte algorithm (as far as lidR is used)
st = segment_trees(ht, dalponte2016(chm, treetops=ttops),uniqueness= "bitmerge")
lidR::writeLAS(st,file.path(envrmt$path_level1,"segements_dalponte.las"))

# have a lk
# x = plot(st,color = "treeID")
# add_treetops3d(x, ttops)

# no filtering for non tree ids and deriving statistics and the projected hull
trees   = lidR::filter_poi(st, !is.na(treeID))

#rm(c(st))
lidR::writeLAS(trees,file.path(envrmt$path_level1,"trees_dalponte.las"))
hulls = lidR::delineate_crowns(trees, type = "concave", concavity = 2,func= .stdmetrics)
# save it to a common  file format
hulls_sf = as(hulls,"sf")
st_crs(hulls_sf) <- epsg
st_write(hulls_sf,file.path(envrmt$path_level1,"sapflow_tree_segments_multichm_dalponte2016.gpkg"),append=FALSE)


