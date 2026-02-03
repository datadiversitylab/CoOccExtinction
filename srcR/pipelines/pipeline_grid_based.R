# GOAL: Create a pipeline for creating the datasets for grid-based analysis
# INPUTS:
#       - Shapefile for an extinct species
#       - Shapefiles for intersecting extant species
#       - Trait data
# OUTPUT:
#       - Dataframe where a row is associated with a lat/lon pair and species,
#         with the appropriate environmental data for that lat/lon pair
#         (See manuscript for further dataframe contents)

library(here)
library(letsR) #install_github("macroecology/letsR")
library(terra)
library(purrr) # For reduce() with rasters
library(tidyr) # For pivot_longer

# List all of the case study directories


pipeline_grid_based <- function(case_studies, rasters, traits, ref){
  
  css_n <- basename(case_studies)
  
  # For each case study:
  ## Read in extinct and extant shapefiles
  ## Combine the shapes for presab
  ## Add environmental rasters
  ## Add trait values
  for(study in css_n) {
    # Read in the trait dataset
    # With new CS naming convention, different numbers of zeros are needed
    
    # Read extinct shapefile
    shp_extinct <- list.files(here("data", "case_studies", study, "extinct"),
                              pattern = "\\.shp$",
                              full.names = TRUE)
    extinct <- vect(shp_extinct)
    
    # Read in extant shapefile
    shp_extant <- list.files(here("data", "case_studies", study, "extant"),
                             pattern = "\\.shp$",
                             full.names = TRUE, 
                             recursive = TRUE)
    extant <- vect(shp_extant)
    
    
    # Ensure that there is a column called "sciname" for downstream
    # Replace existing SCI_NAME
    names(extinct)[3] <- "sciname"
    # Replace existing sci_name
    names(extant)[2] <- "sciname"
    
    # Ensure name of presence column is shared between both
    names(extinct)[4] <- "presence"
    
    # Combine shapes
    all_sp <- rbind(extinct, extant)
    
    # Create PAM object
    ref_r <- rast(here("data", "spatial_data", "reference_grids", ref))
    species_list <- unique(all_sp$sciname)
    pam_layers <- lapply(species_list, function(sp) {
      sp_polygon <- all_sp[all_sp$sciname == sp, ]
      rasterize(sp_polygon, ref_r, field = 1, background = 0)
    })
    PAM_raster <- rast(pam_layers)
    names(PAM_raster) <- species_list
    richness <- sum(PAM_raster)
    occupied_cells <- which(values(richness, mat = FALSE) > 0)
    PAM_matrix <- PAM_raster[occupied_cells]
    
    #Add environmental data
    coords <- xyFromCell(richness, occupied_cells)
    extracted_values <- terra::extract(rasters, coords)
    PAM_df <- data.frame(
      cell_id = occupied_cells,
      lon = coords[, 1],
      lat = coords[, 2],
      PAM_matrix,
      extracted_values
    )
    
    # Add extinct_species_group column
    PAM_df$extinct_species_group <- extinct$sciname
    # Make sure that the extinct species names have underscores, not spaces
    PAM_df$extinct_species_group <- sub(" ", "_", PAM_df$extinct_species_group)
    
    # RESTRUCTURE RESULT DATAFRAME
    # Need:
    # - One row per species x lat/lon pair
    # - Add trait values for each species
    
    # First, identify species columns
    names <- all_sp$sciname
    unique_names <- unique(all_sp$sciname)
    species_cols <- names(PAM_df)[4:(length(unique_names)+3)]
    
    # Need to pivot to long format: each species occurrence is associated with
    #  a lat/lon pair and its appropriate environmental variables
    # The cols argument needs "all_of()" to make it a tidyselect object
    #PAM_long <- pivot_longer(data = PAM_df, cols = all_of(species_cols), 
    #                         names_to = "binomial_name", values_to = "Presence")
    
    
    # Identify non-species columns (everything except species_cols)
    id_cols <- setdiff(names(PAM_df), species_cols)
    
    # Create list of presence records only
    presence_list <- list()
    
    for(sp in species_cols) {
      present_cells <- which(PAM_df[[sp]] == 1)
      
      if(length(present_cells) > 0) {
        presence_list[[sp]] <- data.frame(
          PAM_df[present_cells, id_cols],  # All non-species columns
          binomial_name = sp,
          Presence = 1
        )
      }
    }
    
    # Combine all
    PAM_long <- do.call(rbind, presence_list)
    rownames(PAM_long) <- NULL
    
    # In order to add traits, the binomial_name column needs to include underscores
    PAM_final$binomial_name <- sub(".", "_", PAM_final$binomial_name, fixed = TRUE)
    
    # Include empty columns for trait names
    trait_names <- colnames(traits)[6:length(colnames(traits))]
    for(name in trait_names){
      PAM_final[,name] <- NA
    }
    
    # Populate trait columns for each row
    for(i in c(1:nrow(PAM_final))){
      # Get trait row for the species in the current PAM_final row
      trait_row <- traits[which(traits$species == PAM_final$binomial_name[i]),]
      
      # Only add trait data if it exists
      if(nrow(trait_row) > 0){
        # Add those traits to the PAM_final row
        PAM_final[i, trait_names] <- trait_row[, trait_names]
      }
    }
    
    # Make all column names lowercase
    colnames(PAM_final) <- tolower(colnames(PAM_final))
    # Rename latitude and longitude columns
    colnames(PAM_final)[2] <- "longitude"
    colnames(PAM_final)[3] <- "latitude"
    
    write.csv(PAM_final, here("results", paste0(case_study, ".grid.based.", ref, ".csv")), row.names = FALSE)
  }
}
