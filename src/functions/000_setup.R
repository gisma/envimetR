#----  basic setup envimetR
# install/check from github
devtools::install_github("envima/envimaR")
#devtools::install_github("gisma/uavRst")
devtools::install_github("r-spatial/link2GI")
devtools::install_github("HannaMeyer/CAST")

library(envimaR)
packagesToLoad = c("scriptName","lidR", "link2GI", "mapview", "raster", "rgdal",
                   "rlas", "sp",  "sf" ,"caret", "dplyr","plyr","CAST","doParallel",
                   "sen2r","tidyr","cluster","ClusteR","gtools")

mvTop<-mapview::mapviewPalette("mapviewTopoColors")
mvSpec<-mapview::mapviewPalette("mapviewSpectralColors")

# get viridris color palette
pal<-mapview::mapviewPalette("mapviewTopoColors")

# define some colors for classification
ccols = data.frame("Type" = c('agriculture', 'alder', 'ash', 'beech', 'douglas_fir', 'larch', 'oak', 'pastures', 'roads', 'settlements', 'spruce', 'water'),
                   "col" = c("bisque2","chartreuse4","darkolivegreen","chartreuse3","darkkhaki","aquamarine4","darkseagreen1","darkseagreen2","azure2","darkred","aquamarine"    ,"blue3"))


## dealing with the crs warnings is cumbersome
## for a deeper  however rarely less confusing understanding have a look at:
## https://rgdal.r-forge.r-project.org/articles/CRS_projections_transformations.html
## https://www.r-spatial.org/r/2020/03/17/wkt.html
rgdal::set_thin_PROJ6_warnings(TRUE)

#########################################################################

# define rootfolder
rootDir = envimaR::alternativeEnvi(root_folder = root_folder,
                                   alt_env_id = "COMPUTERNAME",
                                   alt_env_value = "PCRZP",
                                   alt_env_root_folder = "F:/BEN/edu")


# define project specific subfolders
projectDirList   = c("data/",                # datafolders for all kind of date
                     "data/auxdata/",        # the following used by scripts however
                     "data/aerial/level0/",     # you may add whatever you like
                     "data/aerial/org/",     # you may add whatever you like
                     "data/aerial/",     # you may add whatever you like
                     "data/lidar/org/",
                     "data/lidar/",
                     "data/grass/",
                     "data/lidar/level0/",
                     "data/lidar/level1/",
                     "data/lidar/level1/normalized",
                     "data/lidar/level1/ID",
                     "data/lidar/level2/",
                     "data/lidar/level0/all/",
                     "data/data_mof",
                     "data/sentinel/",
                     "data/sentinel/S2/",
                     "data/sentinel/SAFE/",
                     "data/sentinel/sapflow/",
                     "data/tmp/",
                     "data/run/",                # temporary data storage
                     "log/",                # logging
                     "src/",                # scripts
                     "/doc/")                # documentation markdown etc.

############################################################################
############################################################################
############################################################################
# setup of root directory, folder structure and loading libraries
# returns "envrmt" list which contains the folder structure as short cuts
envrmt = envimaR::createEnvi(root_folder = rootDir,
                             folders = projectDirList,
                             path_prefix = "path_",
                             libs = packagesToLoad,
                             alt_env_id = "COMPUTERNAME",
                             alt_env_value = "PCRZP",
                             fcts_folder = file.path(rootDir,"/src/functions"),
                             alt_env_root_folder = "F:/BEN/edu")


# set raster temp path
raster::rasterOptions(tmpdir = envrmt$path_tmp)
# set max memory that speed up the writing process
raster::rasterOptions(maxmemory = 1e+15)
raster::rasterOptions( memfrac  = 0.9)
raster::rasterOptions( chunksize = 9e+08)
raster::rasterOptions( overwrite = TRUE)


###############################
# test area so called "sap flow halfmoon"
xmin = 477500
ymin = 5631730
xmax = 478350
ymax = 5632500
ext=extent(xmin,xmax,ymin,ymax)
sapflow_ext=extent(477500, 478218, 5631730, 5632500)
## define current projection ETRS89 / UTM zone 32N
## the definition of proj4 strings is DEPRCATED have a look at the links under section zero
epsg = 25832
# for reproducible random
set.seed(1000)


