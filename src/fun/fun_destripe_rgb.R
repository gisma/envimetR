#' removes white filling areas of RGB imagery
#' @param files list of tif files to be checked
#' @param envrmt path list of path variables
#' @example
#' tif_files = list.files(envrmt$path_aerial_org, pattern = glob2rx("4*.tif"), full.names = TRUE)
#' destripe_rgb(files = tif_files,
#'              envrmt = envrmt)
#'              destripe_rgb = function(files = tif_files,
#'                                      envrmt = envrmt)

destripe_rgb = function(files = tif_files,
                        envrmt = envrmt)
  {
  # we create a unique combination of all files for a brute force comparision of the extents
  df = combinations(n = length(tif_files), r = 2, v = tif_files, repeats.allowed = FALSE)
  no_comb = nrow(df)
  fixed = 0
  # list for gathering filenames to be deleted
  r_flist= list()


  # for loop for each element of the data frame (nrow())
  for (i in 1:nrow(df)) {
    if (raster(df[i,1])@extent==raster(df[i,2])@extent){ # compare the extent
      print("fix ",df[i,1]," ", df[i,2],"\n")        # output for information 
      new_raster = stack(df[i,1]) + stack(df[i,2]) - 255  # formula to fix
      print("write ",paste0(envrmt$path_aerial_org,basename(max(df[i,]))),"\n") # output for information
      writeRaster(new_raster,  paste0(envrmt$path_aerial_org,basename(max(df[i,]))),overwrite=T) # save it
      print("rename ",paste0(envrmt$path_aerial_org,basename(min(df[i,]))),"\n") # output for information
      r_flist = append(r_flist,paste0(envrmt$path_aerial_org,basename(min(df[i,]))))
      fixed = fixed + 1
    } 
  }
  if (length(r_flist)>0) file.remove(r_flist)
  return(message(getCrayon()[[3]](no_comb ," combinations checked\n ",fixed," images are fixed\n")))
}