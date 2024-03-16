get_layer_counts <- function(las, res = 2)
{
  stats <- lidR::grid_metrics(las, func = LAD(Z, dz = 3,k = 0.5,z0 = 2), res = res)
  #lidR:::as.raster.lasmetrics(stats)
}

# Metrics function to count points within height intervals
layer_count_metrics <- function(Z,breaks,dz=3,z0=2,k=1)
{
  lad <- LAD(z = Z@data$Z,dz = dz,k = k,z0 = z0)



}

metrics_lad <- function(z, zmin=NA, dz = 1, k = 0.5, z0 = 5) {

  if (!is.na(zmin)) z <- z[z>zmin]

  lad_max <- ladprofile <- lad_cv <- lad_min <- lai <- NA_real_

  if(length(z) > 2) {

    ladprofile <- LAD(z, dz = dz, k = k, z0 = z0)
   # print(ladprofile)
    ladprofile$nz = (  ladprofile$z / 45)

    breaks <- seq(0, 1, by = 0.1)

    # Create interval groups for 'z' using cut
    ladprofile$z_group <- cut(ladprofile$nz, breaks = breaks, include.lowest = TRUE, right = TRUE)

    # Aggregate 'lad' values within each 'z' interval using tapply

    sum_lad_by_group <- with(ladprofile, tapply(lad, z_group, sum))

    sum_lad_by_group[is.na(sum_lad_by_group)] <- 0
    sum_lad_by_group[is.infinite(sum_lad_by_group)] = 0
    sum_lad_by_group[!is.numeric(sum_lad_by_group)] = 0
    clean_normalized_lad_profile =  as.data.frame(sum_lad_by_group[!is.na(sum_lad_by_group)])
    rownames(clean_normalized_lad_profile) = paste((seq(0.1, nrow(clean_normalized_lad_profile) / 10, by = 0.1)))
    names(clean_normalized_lad_profile) = "LAD"
   # print(clean_normalized_lad_profile)
  }else {print("FUCK")
    clean_normalized_lad_profile =c(0,0,0,0,0,0,0,0,0,0)
    }
    # lad_max <- with(ladprofile, max(lad, na.rm = TRUE))
    # lad_mean <- with(ladpro file, mean(lad, na.rm = TRUE))
    # lad_cv <- with(ladprofile, sd(lad, na.rm=TRUE)/mean(lad, na.rm = TRUE))
    # lad_min <- with(ladprofile, min(lad, na.rm = TRUE))
    # lai <- with(ladprofile, sum(lad, na.rm = TRUE))



  # lad_metrics <- list(lad_max = lad_max,
  #                     lad_mean = lad_mean,
  #                     lad_cv = lad_cv,
  #                     lad_min = lad_min,
  #                     lai = lai)

  return(clean_normalized_lad_profile)
}


LAD = function(z, dz = 1, k = 0.5, z0 = 2) # (Bouvier et al. 2015)
{
  ld <- gap_fraction_profile(z, dz, z0)

  if (nrow(ld) == 0)
    return(data.frame(z = numeric(0), lad = numeric(0)))

  lad <- ld$gf
  lad <- -log(lad)/(k*dz)

  lad[is.infinite(lad)] = NA

  lad <- lad

  return(data.frame(z = ld$z, lad = lad))
}

gap_fraction_profile2 = function(z, dz = 1, z0 = 2)
{
  zrange = range(z)
  if (z0 < zrange[1])
    z0 = floor((zrange[1]- z0)/dz)*dz + z0

  if (z0 >= zrange[2])
    return(data.frame(z = numeric(0), gf = numeric(0)))

  bk <- seq(z0, ceiling((zrange[2] - z0)/dz)*dz + z0, dz)

  histogram <- graphics::hist(z, breaks = c(-Inf, bk), plot = F)
  h <- histogram$mids
  p <- histogram$counts

  cs <- cumsum(p)
  i <- cs[1:(length(cs)-1)]/cs[2:length(cs)]

  i[is.na(i)] = 0

  z = h[-1]

  return(data.frame(z = z, gf = i))
}

gap_fraction_profile = function(z, dz = 1, z0 = 2)
{
  zrange = range(z)
  if (z0 < zrange[1])
    z0 = floor((zrange[1]- z0)/dz)*dz + z0

  if (z0 >= zrange[2])
    return(data.frame(z = numeric(0), gf = numeric(0)))

  bk <- seq(z0, ceiling((zrange[2] - z0)/dz)*dz + z0, dz)

  histogram <- graphics::hist(z, breaks = c(-Inf, bk), plot = F)
  h <- histogram$mids
  p <- histogram$counts

  cs <- cumsum(p)
  i <- cs[1:(length(cs)-1)]/cs[2:length(cs)]

  i[is.na(i)] = 0
  i[is.infinite(i)] = 0
  z = h[-1]
 #print(data.frame(z = z, gf = i))
  return(data.frame(z = z, gf = i))
}

