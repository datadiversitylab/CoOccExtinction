# GOAL: Write a function that creates a single SpatRaster from all rasters
# INPUTS:
#       - ref: The name of the raster to be used as a reference for resampling
#              NOTE: The name must match the file name for the raster within
#              the spatial_data directory, without the file extension
# OUTPUT:
#       - A single SpatRaster object that combines all of the resampled
#         rasters included in the spatial data folders

library(here)
library(terra)

stack_rasters <- function(ref = "global_1k.tif") {
  
  #Load the reference grid
  ref_r <- rast(here("data", "spatial_data", "reference_grids", ref))
  
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
  
  if(ref == "global_1k.tif"){
    for(i in seq_along(raster_all)){
      raster_all[[i]] <- resample(raster_all[[i]], ref_r, method = "bilinear")
    }
  }else{
    for(i in seq_along(raster_all)  ){
      traster <- raster_all[[i]]
      fact <- round(res(ref_r) / res(traster))
      traster_agg <- aggregate(traster, fact = fact, fun = "mean")
      traster_agg <- resample(traster_agg, ref_r, method = "near")
      raster_all[[i]] <- traster_agg
    }
  }
  
  raster_aligned <- rast(raster_all)
 
  # Return SpatRaster
  return(raster_aligned)
}
