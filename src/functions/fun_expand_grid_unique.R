# for an unique combination of all files in the file list
# google expression: rcran unique combination of vector 
# alternative google expression: expand.grid unique combinations
# have a look at: https://rdrr.io/cran/gimme/src/R/expand.grid.unique.R
expand.grid.unique <- function(x, y, incl.eq = FALSE){
  g <- function(i){
    z <- setdiff(y, x[seq_len(i - incl.eq)])
    if(length(z)) cbind(x[i], z, deparse.level = 0)
  }
  do.call(rbind, lapply(seq_along(x), g))
}
