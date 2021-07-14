#' Surface Albedo using Sentinel-2 images.
#' @export
#'
#' @return It returns TOA Albedo (topA) Surface Albedo (surA) and Surface Albedo  at 24h scale ("Alb_24").
#' @examples
#'
#' # Adapted regression function of the package 'agriwater'
#'
#' # albedo_s2(b2,b3,b4,b8)
#'


calculate_sentinel2_albedo = function(b2=b2,b3=b3,b4=b4,b8=b8){
  
  b2 <- b2/10000
  b3 <- b3/10000
  b4 <- b4/10000
  b8 <- b8/10000
  
  Alb_Top = b2 * 0.32 + b3 * 0.26 + b4 * 0.25 + b8 * 0.17
  Alb_sur = 0.6054 * Alb_Top + 0.0797
  Alb_24 =  1.0223 * Alb_sur + 0.0149
  
  
  return(list(topA = Alb_Top,surA = Alb_sur,dayA = Alb_24))
}