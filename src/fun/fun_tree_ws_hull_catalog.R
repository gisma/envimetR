tree_ws_hull <- function(chunk, dsm, dtm, th,tol,ext, epsg = 25832)
{
  las_chunk = readLAS(chunk)
  if (is.empty(las_chunk)) return(NULL)
  
  ht_chunk <- lidR::normalize_height(las_chunk, dtm)
  algo_all <- lidR::watershed(dsm, th = th,tol = tol,ext = ext)
  ht_ws_chunk <- lidR::segment_trees(ht_chunk, algo_all, uniqueness = "incremental")
  trs_chunk <- lidR::filter_poi(ht_ws_chunk, !is.na(treeID))
  hulls_chunk <- lidR::delineate_crowns(trs_chunk, type = "concave", concavity = 2, func = .stdmetrics)
  
  # Removing the buffer is tricky on this one and
  # this is suboptimal. When used standalone with a
  # catalog delineate_crowns() does the job better than that
  hulls_chunk <- raster::crop(hulls_chunk, raster::extent(chunk))
  hulls_chunk = as(hulls_chunk,"sf")
  return(hulls_chunk)
}