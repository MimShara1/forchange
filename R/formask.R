#' Forest Mask Calculation
#'
#' @param ras_stack    A raster layer stack  containing multiple bands
#' @param bandnames    A character vector specifying the names of the bands in the raster layer stack
#' @param tr_samp      A vector file containing training polygons for land-use classification, used to extract forest area
#'
#' @return
#' A single raster layer representing  only the  forested areas within the specified region of interest
#' 
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
#' ras_stack_path <- system.file("extdata", "roi_2000.tif", package="forchange")
#' ras_stack <- stack(ras_stack_path)
#'
#' tr_samp_path <- system.file("extdata", "samples2000.gpkg", package = "forchange")
#' tr_samp <- st_read(tr_samp_path)
#'
#' bandnames <- c("B01", "B02", "B03", "B04", "B05", "B06", "B07")
#'
#' formask(ras_stack,bandnames,tr_samp)
#' 
#'
#'
#'
#'
formask<-function(ras_stack,bandnames,tr_samp){
  #Load the dataset
  ls_2000<-ras_stack
  bands <- bandnames
  names(ls_2000) <- bands


  # load polygons
  labeled_poly <- tr_samp


  # numeric response variable
  labeled_poly$id
  labeled_poly$resp_var <- labeled_poly$id

  # need labeled features for training:
  # features = predictors (e.g. spectra)
  # labels = response variable (e.g. id, but could be continuous as well, e.g. species richness)

  # to get labeled features,need points to extract features for
  # random selection of points in polygon and  save there labels to them
  labeled_points <- list()
  for(i in unique(labeled_poly$resp_var)){
    message(paste0("Sampling points from polygons with resp_var=", i))

    # sample points for polygons of resp_var = i
    labeled_points[[i]] <- st_sample(
      x = labeled_poly[labeled_poly$resp_var == i,],
      size = 100
    )
    labeled_points[[i]] <- st_as_sf(labeled_points[[i]])
    labeled_points[[i]]$resp_var <- i
  }
  labeled_points <- do.call(rbind, labeled_points)

  # now that we have points we need to extract features
  #  RS data can be used for this since we do not have any ground-truth from site
  #r <- normImage(r)
  #r <- rescaleImage(r, ymin = 0, ymax = 1)

  # extract features and label them with response variable!
  unlabeled_features <- raster::extract(ls_2000, labeled_points, df = T)
  unlabeled_features <- unlabeled_features[,-1] # no ID column needed
  labeled_features <- cbind(
    resp_var = labeled_points$resp_var,
    unlabeled_features
  )

  # remove duplicates (in case multiple points fall into the same pixel)
  dupl <- duplicated(labeled_features)
  which(dupl)
  length(which(dupl)) # number of duplicates in labeled features that  need to remove!
  labeled_features <- labeled_features[!dupl,]

  # x = features
  x <- labeled_features[,2:ncol(labeled_features)] # remove ID column
  y <- as.factor(labeled_features$resp_var) # caret treat this as categories, thus factor
  levels(y) <- paste0("class_", levels(y))


  # fit the model, here a ranodm Forest
  model <- caret::train(
    x = x,
    y = y,
    trControl = caret::trainControl(
      p = 0.75, # percentage of samples used for training, rest for validation
      method  = "cv", #cross validation
      number  = 5, # 5-fold
      verboseIter = TRUE, # progress update per iteration
      classProbs = TRUE # probabilities for each example
    ),
    #preProcess = c("center", "scale"), #center/scale 
    method = "rf" # used algorithm
  )

  # performance
  model
  caret::confusionMatrix(model)



  # predict
  ls_2000_class <- raster::predict(ls_2000, model, type='raw')


  landuse_2000 <- ls_2000_class
  
  
  #mask the forest using forest class value extracted from newly created Landuse classification raster
  unique_values <- unique(values(landuse_2000))  #get the values of classes
  print(unique_values)
  forest_value <- 1
  forest_mask <- landuse_2000 == forest_value
  forest_mask <- as.integer(forest_mask)
  forest_mask[forest_mask == 0] <- NA #subsetting the forest mask to exclude non forest areas


  return(forest_mask)


}
