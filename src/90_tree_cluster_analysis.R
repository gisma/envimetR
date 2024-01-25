#------------------------------------------------------------------------------
# Type: helper script
# Name: 90_tree_cluster_analysis.R
# Author: Chris Reudenbach, creuden@gmail.com
# Description:  - provides some metrics abut clustering and determine the optimal number
#                  clusters as well as the optimal cluster algorithm based on:
#                  Z statistic, LAI,Albedo, Tree species class and 10 LAD classes
#
# Data:  dataframe as provided by the 80_prepare_enviMet_simple_plants.R script
# Output: cluster number and algorithm as well as the clustered data table
# Copyright: Chris Reudenbach, 2021, GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

# 0 - load packages
#-----------------------------
library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))
seed=123
set.seed(seed)


###--------- Estimation of the optimal methods and cluster numbers
#

tree_all_sf = st_read(file.path(envrmt$path_sapflow,"sapflow_tree_all_sf.gpkg"))
dat =st_drop_geometry(tree_all_sf)
tree_tmp = tree_all_sf[ , names(tree_all_sf) %in% c("treeID","geom")]
dat=dat[ , colSums(is.na(dat)) == 0]
tid = dat[ , (names(dat) %in% c("treeID"))]
data_clust = dat[ ,!(names(dat) %in% c("treeID")) ]#,"zmean","zmax","tree_species","lai","albedo"))]
#dat$treeID=tid

# brute force data sampling with half of the data
data = sample_n(data_clust,floor(nrow(dat)* 0.33))


# highspeed
opt = Optimal_Clusters_KMeans(data, max_clusters = 50, plot_clusters = T,num_init = 50,
                              criterion = 'distortion_fK',
                              initializer = 'kmeans++',
                              seed = seed)

 # actually six cluster ist the most stable results using a different sets of variables under the treshold

# kmeans clustering with the number of clusters as derived by opt
km_arma = KMeans_arma(data_clust, clusters = 5, n_iter = 100,
                      seed_mode = "random_subset",
                      verbose = T, CENTROIDS = NULL)
# prediction on all data
data_clust$pr_arma = as.integer(predict_KMeans(data_clust, km_arma))
data_clust$treeID =dat$treeID
class(data_clust$pr_arma)="integer"

# also comprehensive but slow!
# package optCluster performs a statistical validation
# of clustering results and determines the optimal clustering
# algorithm and number of clusters through rank aggreation.
# res_opt_clust <- optCluster::optCluster(data,
#                                         nClust = 2:10,
#                                         clMethods = c("kmeans"),
#                                         validation = c("internal","stability"),
#                                         countData = FALSE,
#                                         rankVerbose = TRUE,maxIter =100)
# summary(res_opt_clust)

# joing the results to sf object
t_cluster = inner_join(data_clust,tree_tmp)
tree_clust_sf = st_as_sf(t_cluster)

# make mean of all combinations of species_mode / pr_arma
# that means we have for each species the 6 clusters as averaged profiles
tree_cluster = t_cluster %>% group_by(species_mode,pr_arma) %>%
  mutate_all(.funs = mean) %>%
  distinct(.keep_all = TRUE)
tree_cluster$geom = NULL
tree_cluster$treeID = NULL


st_write(tree_clust_sf,file.path(envrmt$path_sapflow,"sapflow_tree_all_cluster_sf.gpkg"), append= FALSE)
tree_clust_sf=st_read(file.path(envrmt$path_sapflow,"sapflow_tree_all_cluster_sf.gpkg"))
saveRDS(tree_cluster,file.path(envrmt$path_sapflow,"sapflow_tree_cluster.rds"))
saveRDS(tree_clust_sf,file.path(envrmt$path_sapflow,"sapflow_tree_all_cluster_sf.rds"))
mapview(tree_clust_sf,zcol="pr_arma")
