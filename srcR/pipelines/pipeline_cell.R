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
    study_area_richness <- rasterize(study_area, ref_r_study_area, background = 0, fun = "sum")
    study_area_r_ex <- rasterize(extinct, study_area_r, field = 1, background = 0, touches = TRUE)
    
    #Extract raster data
    occupied_cells <- which(values(study_area_r, mat = FALSE) > 0)
    coords <- xyFromCell(study_area_r, occupied_cells)
    extracted_values <- terra::extract(rasters, coords)
    extracted_values_richness <- terra::extract(study_area_richness, coords)
    cell_classification <- data.frame(
      cell_id = occupied_cells,
      lon = coords[, 1],
      lat = coords[, 2],
      extracted_values, 
      richness = extracted_values_richness[,1]
    )

    occupied_cells_ext <- which(values(study_area_r_ex, mat = FALSE) > 0)
    cell_classification$has_extinct_species <- ifelse(cell_classification$cell_id %in% occupied_cells_ext, TRUE, FALSE)
    
    write.csv(cell_classification,here("results", paste0(case_study, ".cell_based.", ref, ".csv")))
  })
}
