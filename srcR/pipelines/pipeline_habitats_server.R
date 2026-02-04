library(terra)

# Read habitat raster
habitat_lvl2 <- rast("data/spatial_data/raster/discrete/iucn_habitat_lvl2.tif")

# Read traits.csv to access species list
traits <- read.csv("data/traits.csv")
# Make sure that no species are duplicated
species <- unique(traits$species)

# List all of the large shapefiles
shp_files <- list.files(path = "data/large_datasets",
                       pattern = "\\.shp$",
                       full.names = TRUE)
# shp_files <- "data/large_datasets/REPTILES_PART2.shp"
head(shp_files)

# Function to extract the number of habitats for each species in the list
extract_habitats <- function(file_path, raster_obj, species_list) {
  # Read current large shapefile as a vector
  shape_vec <- terra::vect(file_path)
  
  # For each species in the species_list:
  ##  Check if they exist in shape_vec
  ##  If so, extract the number of habitats
  ##  Add info to a row in a dataframe
  
  # Create empty matrix to fill with habitat info
  hab_mat <- matrix(nrow = length(species_list), ncol = 2)
  # Index counter variable
  i <- 1
  
  for(sp in species_list) {
    # Create a SpatVec that just includes the current species
    sp_vec <- shape_vec[shape_vec$sci_name %in% sp, ]
    #sp_vec <- shape_vec[shape_vec$sci_name == sp,]
    
    # If the total area of sp_vec is smaller than a threshold, continue
    # Previous threshold: the area of South America in m^2 1.784e+13
    # Current threshold: 5e+12
    threshold <- 5e+12
    sp_area <- sum(expanse(sp_vec, unit = "m"))
    if(sp_area < threshold){
    
      # If the target species exists in shape_vec, continue
      if(nrow(sp_vec) != 0){
        # Check that the crs exists
        if (terra::crs(sp_vec) == "") terra::crs(sp_vec) <- "EPSG:4326"
        
        # Re-project if necessary
        if (!identical(terra::crs(sp_vec), terra::crs(raster_obj))) {
          sp_vec <- terra::project(sp_vec, terra::crs(raster_obj))
        }
        
        # Extract raster data
        message(paste("Processing", nrow(sp_vec), "polygons for", sp))
        
        n_hab <- tryCatch({
            # Due to memory problems, crop raster_obj to sp_vec first?
            obj_crop <- terra::crop(raster_obj, sp_vec)
            # Mask and use terra::values
            #  so we don't need to create the extracted_info object
            together_mask <- terra::mask(obj_crop, sp_vec)
            vals <- terra::values(together_mask, na.rm = TRUE)
            # extracted_info <- terra::extract(raster_obj, sp_vec)
            # extracted_info <- terra::extract(obj_crop, sp_vec)
        
            # Count the number of habitats (unique, non-NA extracted values)
            # n_hab <- length(unique(extracted_info$iucn_habitat_lvl2[!is.na(extracted_info$iucn_habitat_lvl2)]))
            # n_hab <- length(unique(vals))
  
            # Return for tryCatch
            length(unique(vals))      
        }, error = function(e){
            message(paste("Extraction failed for", sp))
            # Return NA for tryCatch
            NA_integer_
        })
  
        message(paste(sp, "has", n_hab, "habitats"))
        
        # Add extracted data to hab_list
        hab_mat[i,] <- c(sp, n_hab)
        
        # Increment index
        i <- i + 1
  
        # Remove bulky objects and collect garbage
        rm(sp_vec)
        # rm(extracted_info)
        rm(obj_crop)
        rm(together_mask)
        gc()
        
      } # End if
    }
    message("Going to the next species.")
  } # End for
  
  message("Converting to DF and saving")
  # Convert the matrix to a dataframe
  hab_df <- as.data.frame(hab_mat)
  # Rename columns
  colnames(hab_df) <- c("species", "n_habitat")
  # Remove rows with an NA for species (added during initialization)
  hab_df <- hab_df[which(!is.na(hab_df$species)),]
  # Name result file based on shapefile
  file_name <- paste0("results/", basename(file_path), "_nhabitat.csv")
  # Write the CSV
  write.csv(hab_df, file_name, row.names = FALSE)
}

# Run the function for every shapefile
for(shp in shp_files){
  message(paste("Working on this file: ", shp))
  extract_habitats(shp, habitat_lvl2, species)
}
