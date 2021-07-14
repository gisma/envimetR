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
#------------------------------------------------------------------------------


# 0 - load additional packages etc.
#-----------------------------
library(doParallel)
library(plyr)
library(dplyr)
library(caret)
library(CAST)



if(!exists("envrmt")){
  rm(list = ls()) 
  gc()
  require(envimaR)
  source(file.path(envimaR::alternativeEnvi(root_folder = "~/edu/mpg-envinsys-plygrnd/", alt_env_id = "COMPUTERNAME", alt_env_value = "PCRZP", alt_env_root_folder = "F:/BEN/edu/mpg-envinsys-plygrnd"),
                   "msc-phygeo-class-of-2020-creu/src/fun/000_setup.R",fsep = ""))
}

# 2 - define variables
#---------------------
# NOTE you have to adapt the filname according to the prediction stack file
fn="MOF_rgb"
# for saving data
modelname=paste0(fn)

seed=1000

cor_cutoff = 0.9

## read training raw data frame
trainDF = readRDS(paste0(envrmt$path_auxdata,"trainDF_hf_tutorialcourse2020_MOF_rgb.rds"))

# substitute class characteristics
trainDF$Type <- plyr::mapvalues(trainDF$Type, 
                                from=c("EIT", "EIS", "EIR", "FIG", "BUR", "LAE","ESG","ERG","ERS"), 
                                to=c("oak","oak","0ak", "spruce", "beech", "larch","ash","alder","alder"))

fraction_used = 100000/nrow(trainDF)

## read predictor variable stack
predStack = raster::stack(paste0(envrmt$path_aerial,"course2020_MOF_rgb.gri"))

# define name of response variable
response = "Type"

# define number of LLO blocks
no_of_llo_blocks=20



#assign some colors that are easy to interpret visually:
# cols_df = data.frame("Type_en"=c("Buche","Douglasie","Feld","Wiese", "Lärche","Eiche","Strasse","Siedlung", "Spruce", "Wasser"),
                      # "col"=c("brown4", "pink", "wheat", "yellowgreen","lightcoral", "yellow","grey50","red","purple","blue"))

drops <- c("Type", "cell", "coverage_fraction", "geometry","sptlBlc")
keeps <-c( "Type","sptlBlc","spBlock")

# 3 - start code 
#-----------------
##-----------------------------------------------------------------------------

set.seed(seed)

# split data 
cat(getCrayon()[[3]](":::: create data partition \n"))

# filter for +99% coverage pixel
trainDF= st_drop_geometry(trainDF)
trainDF = trainDF[trainDF$coverage_fraction >=0.99,]

# create data parition
trainids = createDataPartition(trainDF$sptlBlc,list=FALSE,p=fraction_used)
trainDF =  trainDF[trainids,]

##  cleaning the training data for a random forest model training
# drop cols
traintmp<-trainDF[ , !(names(trainDF) %in% drops)]

# filter zeor or nearzero Values 
nzv <- nearZeroVar(traintmp)
if (length(nzv)>0) traintmp <- traintmp[, -nzv]

# filter correlations that are > cor_cutoff
filt = findCorrelation(cor(traintmp, use = "complete"), cutoff = cor_cutoff)
traintmp=traintmp[,-filt]

# re-add the necessary variables for model training
traintmp$spBlock=trainDF$sptlBlc
traintmp$Type=trainDF$Type

cat(getCrayon()[[3]](":::: remove NA and find linear Combos \n"))

# remove rows with NA
traintmp=traintmp[complete.cases(traintmp) ,]

# now find and eventually remaining linear combinations of columns
cinfo = findLinearCombos(traintmp[, which(!names(traintmp)%in%keeps)])
if (!is.null(cinfo$remove)) traintmp = traintmp[, -cinfo$remove]

# check manually if there are still NA values around
summary(traintmp)
sapply(traintmp, function(y) sum(length(which(is.na(y)))))

traintmp = traintmp[ , colSums(is.na(traintmp)) == 0]


# if ok create list of predictor names
predictors =names(traintmp[,which(!names(traintmp)%in%keeps)])

# draw subset of training data
trainDat =  traintmp[createDataPartition(traintmp$Type,list=FALSE,p=0.5),]
mtry=length(trainDat)-length(keeps)

# start training + classification
# -----------------------------------------------

## ----- ordinary cv

# define caret control settings
ctrlh <- trainControl(method="cv", 
                      number =10, 
                      savePredictions = TRUE)
# train model 
cl = makeCluster(16)
registerDoParallel(cl)
set.seed(seed)
mod <- train(trainDat[,predictors],
              trainDat[,response],
             method="rf",
             metric="Kappa",
             trControl=ctrlh,
             importance=TRUE
             # ntree=50
             )
stopCluster(cl) 
mod
#predStack2 = readRDS("predstack.rds")
prediction_cv = predict(predStack[[predictors]] , mod,progress ="text")

## ----- ffs
# create spacefolds
folds = CreateSpacetimeFolds(trainDat, spacevar="spBlock", k=no_of_llo_blocks)

# define caret control settings
ctrl_sp = trainControl(method="cv",
                        savePredictions = TRUE,
                        index=folds$index,
                        indexOut=folds$indexOut)

# train model 
cl = makeCluster(4)
registerDoParallel(cl)
set.seed(seed)
ffsmodel_spatial = ffs(trainDat[,predictors],
                        trainDat[,response],
                        method="rf",
                        metric="Kappa",
                        tuneGrid=data.frame("mtry"=mtry),
                        #ntree=50,    # 500 default of the randomforest package
                        trControl = ctrl_sp)
stopCluster(cl) 

# saveRDS(ffsmodel_spatial,file = paste0(envrmt$path_data,modelname,".rds"))
# ffsmodel_spatial = readRDS(paste0(envrmt$path_data,modelname,".rds"))

# plotting the results of the variable selection 
plot_ffs(ffsmodel_spatial)
plot_ffs(ffsmodel_spatial, plotType="selected")

# plot importance
plot(varImp(ffsmodel_spatial))
varImp(ffsmodel_spatial)

# validation of the model
# get all cross-validated predictions and calculate kappa
cvPredictions = ffsmodel_spatial$pred[ffsmodel_spatial$pred$mtry==ffsmodel_spatial$bestTune$mtry,]
k_ffs=round(confusionMatrix(cvPredictions$pred,cvPredictions$obs)$overall[2],digits = 3)

# make model prediction

prediction_ffs = predict(predStack[[predictors]] ,ffsmodel_spatial,progress ="text")

mapview(prediction_cv)+mapview(prediction_ffs)+mapview::viewRGB((predStack2[[1:3]]))

saveRDS(prediction_ffs,paste0(envrmt$path_aerial_level0,"prediction_ffs_",modelname,".rds"))
saveRDS(prediction_cv,paste0(envrmt$path_aerial_level0,"prediction_cv_",modelname,".rds"))

# show results
mapview(prediction_cv)+mapview(prediction_ffs)+mapview::viewRGB((predStack2[[1:3]]))
#mapview(prediction_ffs,col.regions=as.character(cols_df$col))

print(ffsmodel_spatial$selectedvars)
print(ffsmodel_spatial$results)
print(k_ffs)
