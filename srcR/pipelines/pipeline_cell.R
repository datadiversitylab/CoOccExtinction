library(here)
library(terra)
library(dplyr)

css <- list.dirs(here("data", "case_studies"), recursive = FALSE)

print("test")

lapply(css, function(t_cs){
  
  case_study <- basename(t_cs)
  
  # Read in shapefiles
  shp_extinct <- list.files(here("data", "case_studies", case_study, "extinct"),
                            pattern = "\\.shp$",
                            full.names = TRUE)
  extinct <- vect(shp_extinct)
  
  shp_extant <- list.files(here("data", "case_studies", case_study, "extant"),
                           pattern = "\\.shp$",
                           full.names = TRUE, 
                           recursive = TRUE)
  extant <- vect(shp_extant)
  
  # Read in raster data
  rasters <- list.files(here("data", "spatial_data", "raster", "continuous"),
                        full.names = TRUE, 
                        recursive = TRUE)
  raster_list <- lapply(rasters, rast)
  
  
  names(raster_list) <- tools::file_path_sans_ext(basename(rasters))

  rasters_d <- list.files(here("data", "spatial_data", "raster", "discrete"),
                          full.names = TRUE, 
                          recursive = TRUE)
  raster_list_d <- lapply(rasters_d, rast)
  names(raster_list_d) <- tools::file_path_sans_ext(basename(rasters_d))

  # Read in the trait dataset
  traits <- read.csv(here("data", "case_studies", case_study, "traits.csv"))
  
  full_species <- rbind(extant, extinct)

  # CREATE A BUFFER AROUND THE COMBINED RANGE (takes too long)
  # combined_range <- aggregate(full_species)
  # buffer_area <- buffer(combined_range, width = 1000) # 1Km
  # combined_range_proj <- combined_range
  # study_area <- union(buffer_area, full_species)
  study_area <- full_species
  
  # CREATE GRID CELLS FOR THE ENTIRE AREA
  ref <- rast(study_area)
  cell_size <- res(ref)  # Need to fix the resolution
  # clarified the extents and resolutions
  grid_extent <- ext(study_area)
  grid_cells <- rast(grid_extent, resolution=cell_size)
  grid_cells <- as.polygons(grid_cells)
  # grid_cells <- crop(grid_cells, study_area) #potentially necessary but very slow for the case study
  crs(grid_cells)
  
  #create latitude and longitude based on centroids
  centroids<-terra::centroids(grid_cells)
  coords<-terra::crds(centroids)
  grid_cells$longitude<-coords[,1]
  grid_cells$latitude<-coords[,2]
  # unique cell IDs
  grid_cells$cell_id <- 1:nrow(grid_cells)
  
  # extract all of the raster variables for each cell
  raster_vals<-lapply(raster_list,function(x){
    terra::extract(x,grid_cells,fun=mean,na.rm=TRUE)[,-1]
    
  })
  raster_vals_d<-lapply(raster_list_d,function(x){
      terra::extract(x,grid_cells,fun=mean,na.rm=TRUE)[,-1]
  })
      
  val_df<-do.call(cbind,raster_vals)
  names(val_df) <- tools::file_path_sans_ext(basename(rasters))
  
  val_df_d<-do.call(cbind,raster_vals_d)
  names(val_df_d)<-tools::file_path_sans_ext(basename(rasters_d))
  #print(val_df_d)
  

  # CLASSIFY CELLS BASED ON EXTINCT SPECIES PRESENCE

  # Initialize results dataframe
  cell_classification <- data.frame(
    cell_id = grid_cells$cell_id,
    longitude=grid_cells$longitude,
    latitude=grid_cells$latitude,
    has_extinct_species = FALSE,
    extinct_species_count = 0,
    extinct_species_list = NA,
    in_buffer_zone = FALSE,
    val_df,
    val_df_d
    )

  
  # Check each cell for extinct species presence
  for(i in 1:nrow(grid_cells)) {
    current_cell <- grid_cells[i,]
    # Check if cell intersects with extinct species ranges
    intersects_extinct <- relate(current_cell, extinct, "intersects")
    if(any(intersects_extinct)) {
      # Get which extinct species are in this cell
      species_in_cell <- extinct$SCI_NAME[intersects_extinct]

      cell_classification$has_extinct_species[i] <- TRUE
      cell_classification$extinct_species_count[i] <- length(species_in_cell)
      cell_classification$extinct_species_list[i] <- paste(species_in_cell, collapse = ";")
      
    }
  }
  write.csv(cell_classification,here("results",paste0(case_study),"cell_based.csv"))
  })

