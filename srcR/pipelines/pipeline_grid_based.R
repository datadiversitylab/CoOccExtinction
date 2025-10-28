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
library(letsR)
library(terra)
library(purrr) # For reduce() with rasters
library(tidyr) # For pivot_longer

# List all of the case study directories
css <- list.dirs(here("data", "case_studies"), recursive = FALSE)

# List each case study's numeric identifier
css_n <- as.numeric(gsub("\\D", "", css))

# Read in raster data only once, since it won't change per study
source(here("srcR", "misc", "stack_rasters.R"))
# Don't worry, this takes a little while (~45 seconds)
raster_aligned <- stack_rasters("global_elevation_worldclim_2.5arcmin")

# For each case study:
## Read in extinct and extant shapefiles
## Combine the shapes for presab
## Add environmental rasters
## Add trait values
for(study in css_n) {
  # Read in the trait dataset
  # With new CS naming convention, different numbers of zeros are needed
  # For 001-009
  if(study < 10){
    traits <- read.csv(here("data", "case_studies", paste0("CS_00", study), "traits.csv"))
    
    # Read extinct shapefile
    shp_extinct <- list.files(here("data", "case_studies", paste0("CS_00", study), "extinct"),
                              pattern = "\\.shp$",
                              full.names = TRUE)
    extinct <- vect(shp_extinct)
    
    # Read in extant shapefile
    shp_extant <- list.files(here("data", "case_studies", paste0("CS_00", study), "extant"),
                             pattern = "\\.shp$",
                             full.names = TRUE, 
                             recursive = TRUE)
    extant <- vect(shp_extant)
  } else {
    # For 010-099
    traits <- read.csv(here("data", "case_studies", paste0("CS_0", study), "traits.csv"))
    
    # Read extinct shapefile
    shp_extinct <- list.files(here("data", "case_studies", paste0("CS_0", study), "extinct"),
                              pattern = "\\.shp$",
                              full.names = TRUE)
    extinct <- vect(shp_extinct)
    
    # Read in extant shapefile
    shp_extant <- list.files(here("data", "case_studies", paste0("CS_0", study), "extant"),
                             pattern = "\\.shp$",
                             full.names = TRUE, 
                             recursive = TRUE)
    extant <- vect(shp_extant)
  }
  
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
  # Resolution is equivalent to 1 degree of latitude and longitude
  PAM_obj <- lets.presab(all_sp)
  
  # Add aligned raster to incorporate environmental data
  PAM_env <- lets.addvar(x = PAM_obj, y = raster_aligned)
  PAM_df <- as.data.frame(PAM_env)
  
  # Add extinct_species_group column
  PAM_df$extinct_species_group <- extinct$sciname
  
  # RESTRUCTURE RESULT DATAFRAME
  # Need:
  # - One row per species x lat/lon pair
  # - Add trait values for each species
  
  # First, identify species columns
  names <- all_sp$sciname
  unique_names <- unique(all_sp$sciname)
  species_cols <- names(PAM_df)[3:(length(unique_names)+2)]
  
  # Need to pivot to long format: each species occurrence is associated with
  #  a lat/lon pair and its appropriate environmental variables
  # The cols argument needs "all_of()" to make it a tidyselect object
  PAM_long <- pivot_longer(data = PAM_df, cols = all_of(species_cols), 
                           names_to = "binomial_name", values_to = "Presence")
  
  # Should we only include rows with a presence?
  PAM_final <- PAM_long[which(PAM_long$Presence == 1),]
  
  # In order to add traits, the binomial_name column needs to include underscores
  PAM_final$binomial_name <- sub(" ", "_", PAM_final$binomial_name)
  
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
  
  # With new CS naming convention, different numbers of zeros are needed
  # For 001-009
  if(study < 10){
    # Create results directory if it doesn't already exist
    dir.create(here("results", paste0("CS_00", study)))
    
    # Write final CSV
    write.csv(PAM_final, here("results", paste0("CS_00", study), "grid.based.csv"))
  } else {
    # For 010-099
    # Create results directory if it doesn't already exist
    dir.create(here("results", paste0("CS_0", study)))
    
    # Write final CSV
    write.csv(PAM_final, here("results", paste0("CS_0", study), "grid.based.csv"))
  }
  
}
