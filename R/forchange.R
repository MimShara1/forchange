#'  Decadal Forest Change Calculation 
#'
#' 
#' @param diff_NDVI    A raster layer containing NDVI difference between two periods
#' @param threshold    A specific value to be set to determine the extent of change
#'
#' @return
#' A data frame containing forest change area and no change area
#' @export
#'
#' @examples
#'library(forchange)
#'library(raster)
#'library(sp)
#'library(sf)
#'library(RStoolbox)
#'library(caret)
#'library(randomForest)
#'library(terra)
#'
#'
#'
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
#' diff_ndvi(t1_nir, t1_red, t2_nir, t2_red, mask)
#' 
#' diff_NDVI <- diff_ndvi(t1_nir, t1_red, t2_nir, t2_red, mask)
#'
#' threshold <- -0.2
#'
#'
#'forchange(diff_NDVI, threshold)
#
#'
#'
#'
#'
forchange <- function(diff_NDVI, threshold){

  #Set the threshold for highlighting change level
  threshold <- diff_NDVI < -0.2
  th_df_NDVI <- threshold

  #Get the Pixel Values of the raster
  th_df_NDVI.freq <- freq(th_df_NDVI, useNA = "no")
  res_ls <-res(th_df_NDVI)


  #Compute the area in square kilometers
  for_change_area_km2 <- th_df_NDVI.freq[1, "count"] * prod(res_ls) / 1000000
  for_no_change_area_km2 <-th_df_NDVI.freq[2, "count"]* prod(res_ls)/ 1000000

  # Calculate total area in square kilometers
  total_area_km2 <- for_change_area_km2 + for_no_change_area_km2  # Total area is sum of change and no-change areas

  # Calculate percentage of area for each category
  percentage_change_area <- (for_change_area_km2 / total_area_km2) * 100
  percentage_no_change_area <-(for_no_change_area_km2 / total_area_km2) * 100



  # Create data frame
  change_area_df <- data.frame(
    Category = c("Forest Change", "No Change"),
    Area_km2 = c(for_change_area_km2, for_no_change_area_km2),
    Percentage = c(percentage_change_area, percentage_no_change_area)
  )


  # Create the bar plot
  ggplot(change_area_df, aes(x = Category, y = Area_km2, fill = Category)) +
    geom_bar(stat = "identity", width = 0.5) +
    labs(title = "Change in Forest Area Between 2000 and 2020",
         x = "Category",
         y = "Area (sq.km)") +  # Update the y-axis label

    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))




  return(change_area_df)
}
