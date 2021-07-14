get_layer_counts <- function(las, res = 2) 
{
  stats <- lidR::grid_metrics(las, func = LAD(Z, dz = 3,k = 1,z0 = 2), res = res)
  #lidR:::as.raster.lasmetrics(stats)
}

# Metrics function to count points within height intervals
layer_count_metrics <- function(Z,breaks,dz=3,z0=2,k=1) 
{
  lad <- LAD(z = Z@data$Z,dz = dz,k = k,z0 = z0)
  

  
}