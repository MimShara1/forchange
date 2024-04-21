#' NDVI Difference Calculation for two timesteps
#'
#' 
#' @param t1_nir Near Infrared band for the first period
#' @param t1_red Red band for the first period
#' @param t2_nir Near Infrared band for the second period
#' @param t2_red Red band for the second period
#' @param mask   A single raster layer containing only forested areas, used to mask out non-forested areas
#'
#' @return
#' A single raster layer representing NDVI Difference between two timesteps
#' 
#' @export diff_ndvi
#'
#'
#' @examples
#'library(forchange)
#'library(raster)
#'library(sp)
#'library(sf)
#'library(RStoolbox)
#'library(caret)
#'library(randomForest)
#'library(ggplot2)
#'library(terra)
#'
#'
#' t1_nir_path <- system.file("extdata", "l5_nir.tif", package="forchange")
#' t1_nir <- raster(t1_nir_path)
#'
#' t1_red_path <- system.file("extdata", "l5_red.tif", package="forchange")
#' t1_red <- raster(t1_red_path)
#'
#'
#' t2_nir_path <- system.file("extdata", "l8_nir.tif", package="forchange")
#' t2_nir <- raster(t2_nir_path)
#'
#' t2_red_path <- system.file("extdata", "l8_red.tif", package="forchange")
#' t2_red <- raster(t2_red_path)
#'
#' mask_path <- system.file("extdata", "forest_mask.tif", package="forchange")
#' mask<- raster(mask_path)
#'
#'
#'
#' d_ndvi <- diff_ndvi(t1_nir, t1_red, t2_nir, t2_red, mask)
#' plot(d_ndvi)
#'
#'
#'
#'
#'
#'
diff_ndvi <- function(t1_nir, t1_red, t2_nir, t2_red, mask){

  forest_mask <- mask



  #Calculating NDVI for Landsat5 sensor for the   year 2000
  l5_nir <- t1_nir
  l5_red <- t1_red
  ndvi_l5_2000 <- (t1_nir-t1_red)/(t1_nir+t1_red)

  #Overlaying calculated NDVI for year 2000 over forest mask to only get the NDVI values for forested areas
   ndvi_2000 <- overlay(ndvi_l5_2000, mask, fun = "*")


  #Calculating  NDVI for Landsat 8 sensor for the  year 2020
  l8_nir <- t2_nir
  l8_red <- t2_red
  ndvi_l8_2020 <- (t2_nir-t2_red)/(t2_nir+t2_red)

  #Overlaying calculated  NDVI for year 2020 over forest mask to only get the NDVI values for forested areas
  ndvi_2020 <- overlay(ndvi_l8_2020, mask, fun = "*")

  diff_NDVI <- ndvi_2020 - ndvi_2000
  return(diff_NDVI)

}
