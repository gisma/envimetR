#------------------------------------------------------------------------------
# Type:         control script
# Name:         RS_high_resolution data_model_training.R
# Copyright: Hanna Meyer, Chris Reudenbach 2019-2021, GPL (>= 3)
# URL: https://github.com/HannaMeyer/OpenGeoHub_2019/blob/master/practice/ML_LULC.Rmd
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  (1) tidy up of the raw training data set according to used classificator
#               (2) perfom cv and ffs classification worflow

# NOTE:         The tidy up of the the training data can not really done fully unattended
#               However the GOAL of the automatic tidy up is:
#               (1) get rid of data that fails and artifacts (including NA and near zero values)
#               (2) reduction of the number of predictors by dropping the highly linear correlated ones

# Data:         training data dataframe
# Output:       basically checked and dimension reduced data frame containing
#               valid partion of training data for the model training
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------


# 0 - load additional packages etc.
#-----------------------------

library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))

# 2 - define variables
#---------------------
cat(getCrayon()[[3]](":::: read train data frame  \n"))

# NOTE adapt the filename according to the prediction stack file

fn = "5-25_MOF_rgb"
# extraction type random, hexagonal ,
sample_type = "regular"
seed=123
trainDF=trainDF_ex
# ---- Data input if not done by
# trainDF = readRDS(paste0(tools::file_path_sans_ext(fbFN),sample_type,".rds"))
# predStack_PCA =raster::stack(paste0(envrmt$path_aerial,fn,"_final_predictors_otb_pca_10.tif"))
# names(predStack_PCA)=c("PC1","PC2","PC3","PC4","PC5","PC6","PC7","PC8","PC9","PC10")
# substitute class characteristics
trainDF$Type <- plyr::mapvalues(trainDF$Type,
                                from = c("EIT", "EIS", "EIR", "FIG", "BUR", "LAE","ESG","ERG","ERS","DGL","Grassland","Road","Settlement","Water","Field"),
                                to = c("oak","oak","oak", "spruce", "beech", "larch","ash","alder","alder","douglas_fir","pastures","roads","settlements","water","agriculture"))

# roughly 100K training samples will be extracted
tp_goal = 100000

train_partition = 0.25

# define name of response variable
response = "Type"

# define number of LLO blocks
no_of_llo_blocks = 20



# define cols for dropping and keeping
drops = c( "cell", "coverage_fraction")#, "geometry","sptlBlc")
keeps = c( "Type","sptlBlc")

# 3 - start code
#-----------------
##-----------------------------------------------------------------------------

set.seed(seed)

# split data

trainDF = st_drop_geometry(trainDF)
trainDF = trainDF[trainDF$coverage_fraction >= 1,]
fraction_used = tp_goal/nrow(trainDF)

# create data partition
trainids = createDataPartition(trainDF$sptlBlc,list = FALSE,p = fraction_used)
trainDF =  trainDF[trainids,]
# drop cols
trainDF = trainDF[ , !(names(trainDF) %in% drops)]

summary(trainDF)
sapply(trainDF, function(y) sum(length(which(is.na(y)))))

# if ok create list of predictor names
predictors = names(trainDF[,which(!names(trainDF) %in% keeps)])

# draw subset of training data
trainDat =  trainDF[createDataPartition(trainDF$Type,list = FALSE,p = train_partition),]
mtry = length(trainDat) - length(keeps)


## ---- training + classification
# -----------------------------------------------

## ----- ordinary cv
# define caret control settings
ctrlh = trainControl(method = "cv",
                      number = 10,
                      savePredictions = TRUE)
# train model
cl = makeCluster(16)
registerDoParallel(cl)
set.seed(seed)
cv_model = train(trainDat[,predictors],
             trainDat[,response],
             method = "rf",
             metric = "Kappa",
             trControl = ctrlh,
             importance = TRUE
             # ntree = 50
)
stopCluster(cl)
saveRDS(cv_model,file = paste0(envrmt$path_data,"cv_model_",fn,".rds"))
cv_model



## ----- ffs
# create spacefolds
folds = CreateSpacetimeFolds(trainDat, spacevar = "sptlBlc", k = no_of_llo_blocks)

# define caret control settings
ctrl_sp = trainControl(method = "cv",
                       savePredictions = TRUE,
                       index = folds$index,
                       indexOut = folds$indexOut)

# train model
cl = makeCluster(10)
registerDoParallel(cl)
set.seed(seed)
ffsmodel_spatial = ffs(trainDat[,predictors],
                       trainDat[,response],
                       method = "rf",
                       metric = "Kappa",
                       tuneGrid = data.frame("mtry" = mtry),
                       #ntree = 50,    # 500 default of the randomforest package
                       trControl = ctrl_sp)
stopCluster(cl)
ffsmodel_spatial
saveRDS(ffsmodel_spatial,file = paste0(envrmt$path_data,"ffs_model_",fn,".rds"))

# plotting the results of the variable selection
plot_ffs(ffsmodel_spatial)
plot_ffs(ffsmodel_spatial, plotType = "selected")

# plot importance
plot(varImp(ffsmodel_spatial))
varImp(ffsmodel_spatial)

# validation of the model
# get all cross-validated predictions and calculate kappa
cvPredictions = ffsmodel_spatial$pred[ffsmodel_spatial$pred$mtry == ffsmodel_spatial$bestTune$mtry,]
k_ffs = round(confusionMatrix(cvPredictions$pred,cvPredictions$obs)$overall[2],digits = 3)

print(ffsmodel_spatial$selectedvars)
print(ffsmodel_spatial$results)
print(k_ffs)

# saveRDS(prediction_ffs,paste0(envrmt$path_aerial_level0,"prediction_ffs_",modelname,".rds"))
# saveRDS(prediction_cv,paste0(envrmt$path_aerial_level0,"prediction_cv_",modelname,".rds"))

## ---- make model predictions
#polishedMap <- focal(sc$map, matrix(1,3,3), fun = modal)
#otb ClassificationMapRegularization

sapflow = raster::crop(predStack_PCA,extent(477500, 478218, 5631730, 5632500))
prediction_cv_PCA  = predict(predStack_PCA[[predictors]] ,cv_model, progress = "text")
prediction_ffs_PCA = predict(predStack_PCA[[predictors]] ,ffsmodel_spatial,progress = "text")
sapflow_prediction_cv_PCA = raster::crop(prediction_cv_PCA,extent(477500, 478218, 5631730, 5632500))
sapflow_prediction_ffs_PCA = raster::crop(prediction_ffs_PCA,extent(477500, 478218, 5631730, 5632500))
saveRDS(prediction_ffs_PCA,paste0(envrmt$path_aerial_level0,"sfprediction_ffs_",fn,".rds"))
saveRDS(prediction_cv_PCA,paste0(envrmt$path_aerial_level0,"sfprediction_cv_",fn,".rds"))

crs(dtm) = projection(predStack_PCA)

# show results
mapview(prediction_ffs_PCA,col.regions=as.character(ccols$col)) +
  mapview(prediction_cv_PCA,col.regions=as.character(ccols$col))

