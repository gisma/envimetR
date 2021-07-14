#------------------------------------------------------------------------------
# Type: control script 
# Name: 30_RS_extract_training_data_PCA.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  extract raw training data according to training areas
#               * it uses the forest inventories to automatically generate 
#                 training areas for tree species
#               * furthermore an additional training data set of 
#                 e.g. corine or manually digitized data will be combined
#               The number of sampling positions and the type of sampling 
#               can be determined. a defined buffer is created around the 
#               positions and the training values are extracted from these. 
#               The tree species are drawn in proportion to their area.
#               The resulting data is tidy up and then a 10 class PCA is performed 
#               The final training data set is derived by extracting the data at the 
#               same positions as before. This will significantly speed up the 
#               training as well as it makes the classification more robust.
# Data:         raster data stack of prediction variables , training areas
# Output:       raw dataframe containing training data

# Copyright: Chris Reudenbach 2019-2020, GPL (>= 3)
#------------------------------------------------------------------------------


# 0 - load packages
#-----------------------------
library(caret)
library(exactextractr)
library(dplyr)
library(sf)

if (!exists("envrmt")) {
  # 0 - load packages
  #-----------------------------
  require(envimaR)
  rm(list = ls()) 
  gc()  
  envrmt = list()
  # 1 - source files
  #-----------------
  source(file.path(envimanamesR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd", alt_env_id = "COMPUTERNAME", alt_env_value = "PCRZP", alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                   "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R"))
}

# clean run dir
unlink(paste0(envrmt$path_tmp,"*"), force = TRUE)


# 2 - define variables
#-----------------------------
# get the prediction stack  (load  and apply bandnames)
# NOTE you have to adapt the filname according to the prediction stack file
fn = "5-25_MOF_rgb"

# numbers of training points 
no_sample = 7500
critical_training_classes = c("Water","Road","Settlement") # small or poorly digitized classes but NO forest classes
area_share_for_non_inventory = 0.25   # all excluding forest inventory and critical_training_classes
cc_value_th = 0.05 # threshold for small areas forest classes or cc
cc_value = 0.01
# radius of buffer around the extracting points
buffer_size = .5
# extraction type random, hexagonal , 
sample_type = "regular"
# cut of level of correlated predictors that are rejected
cor_cutoff = 0.8
# roughly 100K training samples will be extracted
tp_goal = 100000
train_partition = 0.25
# define name of response variable
response = "Type"
# define cols for dropping and keeping
drops = c("Type", "cell", "coverage_fraction", "geometry","sptlBlc")
keeps = c( "Type","sptlBlc","spBlock")

# assign the prediction stack as derived by 20_calculatesynbands
predStack  = raster::stack(paste0(envrmt$path_aerial,fn,".gri"))

# training data  
# have also a look at https://github.com/HannaMeyer/OpenGeoHub_2019/tree/master/practice/data
trainSites = sf::read_sf(file.path(envrmt$path_auxdata,"training_MOF_1m.shp"))
trainSites = sf::st_transform(trainSites,crs = projection(predStack))
spfolds = sf::read_sf(file.path(envrmt$path_auxdata,"spfolds.shp"))
spfolds = sf::st_transform(spfolds,crs = projection(predStack))
# HessenForst inventory
train_data = sf::read_sf(file.path(envrmt$path_auxdata,"forest_divisions.shp"))
train_data = sf::st_transform(train_data,crs = projection(predStack))
# crop the HF training data to the raster stack
train_data = st_crop(train_data,st_bbox(predStack))
# filter for nan tree areas
train_data_nan = train_data %>% filter(!mainTreeSp == "na")
train_data_union = st_union(train_data_nan) 
# retrieve the main tree species without nan
species = unique(train_data_nan$mainTreeSp)
# calculate reference tree area
all_trees_area = st_area(train_data_union)

# intersect the other training data  from the inventory area
t = st_make_valid(train_data_nan)
s = st_make_valid(trainSites)
t =  t[,"mainTreeSp"]
names(t) = c("Type","geometry")
s =  s[,"Type"]
s  = rmapshaper::ms_erase(s,t)
dtd = rbind(t,s)
train_data = dtd[!dtd$Type %in% c("Larch","Oak","Douglas Fir","Spruce","Beech"),]
# calculate reference tree area
all_trees_area = st_area(st_union(train_data))

# extract sample points and add tree species
# retrieve the main tree species without nan
species  =  unique(train_data$Type)
distinct_df = list()
td_df = list()
cat("generating ",sample_type," sampling position of training data....\n")
for (spec in species) {
  area_share  =  as.numeric(sum(train_data %>% group_by(Type) %>% filter(Type == spec) %>% st_area())/as.numeric(all_trees_area))
  if (!spec %in% c("BUR","EIT","FIG","ESG","DGL","LAE","ERS")) area_share = area_share_for_non_inventory
  if (spec %in%  critical_training_classes | area_share < cc_value_th) area_share = cc_value
  if (area_share > 0) {
  distinct_df[[spec]] = train_data %>% group_by(Type) %>% filter(Type == spec) %>% st_sample(no_sample*area_share,type = sample_type,exact = TRUE)
  distinct_df[[spec]] = st_sf(Type = spec, geom = distinct_df[[spec]])
  cat(spec," ",nrow(distinct_df[[spec]])," \n")
  }
}
train_data_DF = do.call(rbind, distinct_df)
train_data_DF = st_buffer(train_data_DF,buffer_size)


## using the exactextractr packageby 100 times+ faster than raster::extract 
tDF_ex = exactextractr::exact_extract(predStack, train_data_DF,  force_df = TRUE,
                                      include_cell = TRUE,include_xy = TRUE,full_colnames = TRUE,include_cols = "Type") 
tDF_ex = dplyr::bind_rows(tDF_ex) 

# brute force approach to get rid of NA
tDF_ex = tDF_ex[ , colSums(is.na(tDF_ex)) == 0]

# conversion to a spatial sf object
tDF_ex_sf = sf::st_as_sf(tDF_ex ,
                         coords = c("x", "y"),
                         crs = projection(predStack),
                         agr = "constant")
# spatial merge via intersection
trainDF = st_intersection(tDF_ex_sf,spfolds)
summary(trainDF)

# save the raw training data
saveRDS(trainDF,paste0(envrmt$path_auxdata,"trainDF_hf_tutorial_PCA",sample_type,fn,".rds"))



#############
###########
############

# substitute class characteristics
trainDF$Type <- plyr::mapvalues(trainDF$Type, 
                                from = c("EIT", "EIS", "EIR", "FIG", "BUR", "LAE","ESG","ERG","ERS","DGL","Grassland","Road","Settlement","Water","Field"), 
                                to = c("oak","oak","oak", "spruce", "beech", "larch","ash","alder","alder","douglas_fir","pastures","roads","settlements","water","agriculture"))

set.seed(seed)

# clean data
trainDF = st_drop_geometry(trainDF)
trainDF = trainDF[trainDF$coverage_fraction >= 1,]
fraction_used = tp_goal/nrow(trainDF)

# create data partition
trainids = createDataPartition(trainDF$sptlBlc,list = FALSE,p = fraction_used)
trainDF =  trainDF[trainids,]

## ----  cleaning the training data for a random forest model training
traintmp = trainDF[ , !(names(trainDF) %in% drops)]

# filter zero or near-zero values 
nzv = nearZeroVar(traintmp)
if (length(nzv) > 0) traintmp = traintmp[, -nzv]

# filter correlations that are > cor_cutoff
filt = findCorrelation(cor(traintmp, use = "complete"), cutoff = cor_cutoff)
traintmp = traintmp[,-filt]

# re-add the necessary variables for model training
traintmp$spBlock = trainDF$sptlBlc
traintmp$Type = trainDF$Type

cat(getCrayon()[[3]](":::: remove NA and linear combos \n"))
# remove rows with NA
traintmp = traintmp[complete.cases(traintmp) ,]
traintmp = traintmp[ ,colSums(is.na(traintmp)) == 0]

# now find and eventually remaining linear combinations of columns
cinfo = findLinearCombos(traintmp[, which(!names(traintmp) %in% keeps)])
if (!is.null(cinfo$remove)) traintmp = traintmp[, -cinfo$remove]

# check manually if there are still NA values around
summary(traintmp)
sapply(traintmp, function(y) sum(length(which(is.na(y)))))


#############
###########
############


# Now we reduce dimension via PCA
# if ok create list of predictor names
predictors_for_PCA = names(traintmp[,which(!names(traintmp) %in% keeps)])


# create otb command for PCA
otb  = link2GI::linkOTB(searchLocation = "/usr/bin/")
# assign the prediction stack
fbFN = paste0(envrmt$path_aerial,fn,"_final_predictors.tif")
predStack  = raster::stack(paste0(envrmt$path_aerial,fn,".gri"))
writeRaster(predStack[[predictors_for_PCA]],fbFN,progress="text",overwrite=TRUE)
pca = parseOTBFunction("DimensionalityReduction",otb)
pca$input_in = fbFN
pca$out = paste0(envrmt$path_aerial,fn,"_final_predictors_otb_pca_10.tif")
pca$progress = "true"
pca$normalize = "true"
pca$nbcomp=10
pca$progress = "true"
predStack_PCA = runOTB(pca,gili = otb,retRaster = TRUE,quiet = FALSE)  
# rename layers
names(predStack_PCA)=c("PC1","PC2","PC3","PC4","PC5","PC6","PC7","PC8","PC9","PC10")



#############
###########
############

# extract final training data

tDF_ex = exactextractr::exact_extract(predStack_PCA, train_data_DF,  force_df = TRUE,
                                      include_cell = TRUE,include_xy = TRUE,full_colnames = TRUE,include_cols = "Type") 
tDF_ex = dplyr::bind_rows(tDF_ex) 

# brute force approach to get rid of NA
tDF_ex = tDF_ex[ , colSums(is.na(tDF_ex)) == 0]

# conversion to a spatial sf object
tDF_ex_sf = sf::st_as_sf(tDF_ex ,
                         coords = c("x", "y"),
                         crs = projection(predStack_PCA),
                         agr = "constant")
# spatial merge via intersection
trainDF_ex = st_intersection(tDF_ex_sf,spfolds)
summary(trainDF_ex)

# save the final training data
saveRDS(trainDF_ex,paste0(tools::file_path_sans_ext(fbFN),sample_type,".rds"))



