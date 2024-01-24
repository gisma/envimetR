#------------------------------------------------------------------------------
# Type: control script
# Name: 30_make_enviMet_simple_plants.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  derives tree hulls and the corresponding values for
#               tree species, height, LAD , albedo, transmissivity, root profile,
#               lucc classes and seasonality
# Data: point cloudand dsm and dtm as derived by 10_CHM_Catalog.R
#       sentinel 2 bands 2,3,4,8, classification of tree species  40_RS_high_resolution data
# Output: Envimet simple plant database file
# Copyright: Chris Reudenbach 2021, GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))


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

min_tree_height = 2

trees=lidR::readLAS(file.path(envrmt$path_sapflow,"sapflow_tree_segments_multichm_dalponte2016.las"))
hulls_sf=st_read(file.path(envrmt$path_sapflow,"sapflow_tree_segments_multichm_dalponte2016.gpkg"))

# get and filter the classification map
sapflow_species=readRDS(paste0(envrmt$path_aerial_level0,"sfprediction_ffs_",fn,".rds"))
sapflow_species = raster::crop(sapflow_species,extent(477500, 478218, 5631730, 5632500))

#ClassificationMapRegularization majority filter
otb  = link2GI::linkOTB(searchLocation = "~/apps/OTB-8.1.2-Linux64/")
# assign the prediction stack
fbFN = paste0(envrmt$path_aerial,fn,"_majority_in.tif")
writeRaster(sapflow_species,fbFN,progress="text",overwrite=TRUE)
cmr = parseOTBFunction("ClassificationMapRegularization",otb)
cmr$io.in = fbFN
cmr$io.out = paste0(envrmt$path_aerial,fn,"_majority_out.tif")
cmr$progress = "true"
cmr$ip.radius = "1"



filter_treespecies = runOTB(cmr,gili = otb$pathOTB,quiet = FALSE,retRaster = TRUE)
#filter_treespecies=raster(paste0(envrmt$path_aerial,fn,"_majority_out.tif"))

## extract the values
species_ex = exactextractr::exact_extract(filter_treespecies, hulls_sf,  force_df = TRUE,
                                         include_cols = "treeID")
species_ex = dplyr::bind_rows(species_ex)

# calulate mode per tree
species_hulls = species_ex %>% group_by(treeID) %>%
  dplyr::reframe(species_median = median(value, na.rm=TRUE),
                   species_mode = modeest::mlv(value, method='mfv'))
species_hulls = inner_join(hulls_sf,species_hulls)
species_sf=species_hulls[,c("treeID","ZTOP","zmax","zmean","zsd","zskew","species_mode","area")]
st_write(species_hulls,file.path(envrmt$path_level1,"sapflow_tree_segments_multichm_dalponte2016_species.gpkg"),append=FALSE)
#species_hulls = st_read(file.path(envrmt$path_sapflow ,"sapflow_tree_segments_multichm_dalponte2016_species.gpkg"))

# calculate the LAD metrics for the derived trees
# review vertical LAI ditribution http://dx.doi.org/10.3390/rs12203457
lad_tree = tree_metrics(trees, func = ~LAD(Z))
# GAP and transmittance metrics
# https://www.isprs.org/proceedings/xxxvi/3-W52/final_papers/Hopkinson_2007.pdf
gap_tree = tree_metrics(trees, func = ~lidR::gap_fraction_profile(Z))
gap_tree$gf = gap_tree$gf * 0.8
plot(gap_tree)
lt=st_drop_geometry(as(lad_tree,"sf"))
lad_trees = inner_join(lt,species_sf)

tmp = lt %>%
  group_by(treeID,z) %>%
  spread(z,lad,fill = 0,sep = "_")
lad_trees =  inner_join(tmp,lad_trees)


# read the setntinel data
albedo = raster(paste0(envrmt$path_sapflow,"S2B2A_20210613_108_sapflow_BOA_10_albedo.tif"))
lai = raster(paste0(envrmt$path_sapflow,"2021-06-13-00:00_2021-06-13-23:59_Sentinel-2_L1C_Custom_script.tiff"))

## extract the values
lai_ex = exactextractr::exact_extract(lai, hulls_sf,  force_df = TRUE,
                                         include_cols = "treeID")
lai_ex = dplyr::bind_rows(lai_ex)
lai_ex$coverage_fraction=NULL
names(lai_ex)=c("treeID","lai")
alb_ex = exactextractr::exact_extract(albedo, hulls_sf,  force_df = TRUE,
                                      include_cols = "treeID",)
alb_ex = dplyr::bind_rows(alb_ex)
alb_ex$coverage_fraction=NULL
names(alb_ex)=c("treeID","albedo")
l_trees =  inner_join(lai_ex,lad_trees)
a_trees = inner_join(alb_ex,l_trees)

# make mean of all unique treeIds
tree = a_trees %>% group_by(treeID) %>%
  mutate_all(.funs = mean) %>%
  distinct(.keep_all = TRUE)
tree$geom =NULL
t_lad=tree
tree_clust = tree[,c("treeID","albedo","lai","zmax","zmean","zskew","species_mode")]


tree_tmp = hulls_sf[ , names(hulls_sf) %in% c("treeID","geom")]
t=inner_join(tree_clust,tree_tmp)
tree_clust_sf=st_as_sf(t)
mapview(tree_clust_sf,zcol="albedo")
#t=st_drop_geometry(trees_sf)
header_height=seq(2.5,44.5,1)
#header_height=c(2.5, 3.5,   4.5,   5.5,   6.5,   7.5,   8.5,   9.5,   10.5,  11.5,  12.5,  13.5,  14.5,  15.5,  16.5,17.5,  18.5,  19.5,  20.5,  21.5,  22.5,  23.5,  24.5,  25.5,  26.5,  27.5,  28.5,  29.5,  30.5,  31.5,  32.5,33.5,  34.5,  35.5,  36.5,  37.5,  38.5,  39.5,  40.5,  41.5,  42.5,  43.5,  44.5)
lad= tree %>% distinct(across(contains(".5")))
norm1 = (lad[][2:length(lad)] - min(lad[][2:length(lad)] ))/ (max(lad[][2:length(lad)])-min(lad[][2:length(lad)]))
lad_spl = by(norm1, seq_len(nrow(norm1)), function(row) {try(smooth.spline(header_height, row,spar = 0.1))
  })

# for (i in seq(9000:9050)){
#   plot(lad_spl[[i]]$data$x,lad_spl[[i]]$data$y)
#   lines(lad_spl[[i]], lty = 2, col = "red")
#   lines( predict(lad_spl[[i]], xx), col = "green")
# }

xx = unique(sort(c(seq(4, 40, by = 4))))
lad_pred = lapply(lad_spl, function(x){predict(x, xx)[[2]]})
lad_pred = abs(as.data.frame(do.call(rbind, lad_pred)))
names(lad_pred)= paste0("lev_",xx)
lad_pred$treeID = lad$treeID


trees_all = inner_join(lad_pred,tree_clust)
trees_all =inner_join(trees_all,tree_tmp )
trees_all_sf=st_as_sf(trees_all)
st_write(trees_all_sf,file.path(envrmt$path_sapflow,"sapflow_tree_all_sf.gpkg"),append = FALSE)
trees_all_sf=st_read(file.path(envrmt$path_sapflow,"sapflow_tree_all_sf.gpkg"))
