# GOAL: Write a function that creates a single SpatRaster from all rasters
# INPUTS:
#       - ref: The name of the raster to be used as a reference for resampling
#              NOTE: The name must match the file name for the raster within
#              the spatial_data directory, without the file extension
# OUTPUT:
#       - A single SpatRaster object that combines all of the resampled
#         rasters included in the spatial data folders

stack_rasters <- function(ref = "global_elevation_worldclim_2.5arcmin") {
  # First, read in continuous rasters
  rasters_c <- list.files(here("data", "spatial_data", "raster", "continuous"),
                          full.names = TRUE, 
                          recursive = TRUE)
  raster_list_c <- lapply(rasters_c, rast)
  # Apply file names to list
  names(raster_list_c) <- tools::file_path_sans_ext(basename(rasters_c))
  
  # Next, read in discrete rasters
  rasters_d <- list.files(here("data", "spatial_data", "raster", "discrete"),
                          full.names = TRUE, 
                          recursive = TRUE)
  raster_list_d <- lapply(rasters_d, rast)
  # Apply file names to list
  names(raster_list_d) <- tools::file_path_sans_ext(basename(rasters_d))
  
  # Combine them in one list
  raster_all <- c(raster_list_c, raster_list_d)
  
  # Make sure rasters can be stacked
  # Use terra::resample to ensure that all geometries align
  # Use ref as the baseline
  ref <- raster_all[[ref]]
  
  for(i in c(1:length(raster_all))){
    # If the layer is continuous, then the resampling method should be "bilinear"
    # (The continuous rasters are the first n of raster_all, where n is the 
    #  length of raster_list_c)
    if(i <= length(raster_list_c)){
      raster_all[[i]] <- resample(raster_all[[i]], ref, method = "bilinear")
    } else {
      # If the layer is discrete, then the resampling method should be "near"
      raster_all[[i]] <- resample(raster_all[[i]], ref, method = "near")
    }
  }
  
  # Finally, use terra::c() to collapse the transformed raster_all list
  #  into one SpatRaster for use with lets.addvar()
  raster_aligned <- reduce(raster_all, c)
  
  # Return SpatRaster
  return(raster_aligned)
  
}
