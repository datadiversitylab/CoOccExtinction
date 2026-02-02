library(here)
library(terra)
library(dplyr)

pipeline_cell <- function(case_studies, rasters, traits, ref){
  
  css <- case_studies
  
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
    
    full_species <- rbind(extant, extinct)
    
    study_area <- full_species
    # CREATE GRID CELLS FOR THE ENTIRE AREA
    ref_r <- rast(here("data", "spatial_data", "reference_grids", ref))
    ref_r_study_area <- crop(ref_r, study_area)
    study_area_r <- rasterize(study_area, ref_r_study_area, field = 1, background = 0)
    
    #Extract raster data
    occupied_cells <- which(values(study_area_r, mat = FALSE) > 0)
    coords <- xyFromCell(study_area_r, occupied_cells)
    extracted_values <- terra::extract(rasters, coords)
    cell_classification <- data.frame(
      cell_id = occupied_cells,
      lon = coords[, 1],
      lat = coords[, 2],
      extracted_values
    )
  
    # CLASSIFY CELLS BASED ON EXTINCT SPECIES PRESENCE
    all_points <- vect(cell_classification[, c("lon", "lat")], 
                       geom = c("lon", "lat"),
                       crs = crs(extinct))
    
    # Extract which extinct polygons each point intersects
    intersections <- relate(all_points, extinct, "intersects")
    
    # Initialize columns
    cell_classification$has_extinct_species <- FALSE
    cell_classification$extinct_species_count <- 0
    cell_classification$extinct_species_list <- ""
    
    # Process only cells that intersect
    for(i in 1:nrow(cell_classification)) {
      if(any(intersections[i, ])) {
        species_in_cell <- extinct$SCI_NAME[intersections[i, ]]
        cell_classification$has_extinct_species[i] <- TRUE
        cell_classification$extinct_species_count[i] <- length(species_in_cell)
        cell_classification$extinct_species_list[i] <- paste(species_in_cell, collapse = ";")
      }
    }
    write.csv(cell_classification,here("results",paste0(case_study),"cell_based.csv"))
  })
}
