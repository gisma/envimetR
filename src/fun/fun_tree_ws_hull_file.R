tree_ws_hull_las <- function(chunk, dsm, dtm, th,tol,ext, epsg = 25832)
{
  las_chunk = las_file
  chm=csm-dtm
  ht_chunk <- lidR::normalize_height(las_chunk, dtm)
  #algo_all <- lidR::watershed(dsm, th = th,tol = tol,ext = ext)
  #ht_ws_chunk <- lidR::segment_trees(ht_chunk, algo_dp, uniqueness = "incremental")  
  f <- function(x) { x * 0.07 + 3 }
  ttops <- find_trees(chm, lmf(f,hmin = 8,shape = "circular"))
  ht_ws_chunk = segment_trees(las_chunk, dalponte2016(chm, ttops))

  trs_chunk <- lidR::filter_poi(ht_ws_chunk, !is.na(treeID))
  hulls_chunk <- lidR::delineate_crowns(trs_chunk, type = "concave", concavity = 2, func = .stdmetrics)
  
  # Removing the buffer is tricky on this one and
  # this is suboptimal. When used standalone with a
  # catalog delineate_crowns() does the job better than that
  #hulls_chunk <- raster::crop(hulls_chunk, raster::extent(chunk))
  hulls_chunk = as(hulls_chunk,"sf")
  return(hulls_chunk)
}