library(here)
library(terra)
library(dplyr)

case_study <- 1

# Read in shapefiles
shp_extinct <- list.files(here("data", "case_studies", paste0("cs", case_study), "extinct"),
                        pattern = "\\.shp$",
                        full.names = TRUE)
extinct <- vect(shp_files)

shp_extant <- list.files(here("data", "case_studies", paste0("cs", case_study), "extant"),
                          pattern = "\\.shp$",
                          full.names = TRUE, 
                         recursive = TRUE)
extant <- lapply(shp_extant, vect)

# Read in raster data
rasters <- list.files(here("data", "spatial_data", "raster"),
                         full.names = TRUE, 
                         recursive = TRUE)
raster_list <- lapply(rasters, rast)
names(raster_list) <- tools::file_path_sans_ext(basename(rasters))


# Read in the trait dataset

#traits <- read.csv(here("data", "case_studies", paste0("cs", case_study), "trait_test.csv"))
traits <- read.csv(here("data", "case_studies", paste0("cs", case_study), "traits.csv"))

# Construct dataset

full_species <- c(extant, extinct)

caseStudy <- lapply(seq_along(full_species), function(sp){
  print(sp)

  target_sp <- full_species[[sp]]
  extinct_sp <- full_species[[length(full_species)]]
  
  species_name <- sub(" ", "_",  full_species[[sp]]$sciname[1])
  
  # 2. TRAITS (from traits CSV)
  trait_row <- traits %>% filter(species == species_name)
  
  if (nrow(trait_row) == 0) {
    stop(paste("No traits found for", species_name))
  }
  
  # 3. RANGE METRICS
  # Area
  global_range_size_km2 <- sum(expanse(target_sp, unit = "km"))
  global_range_size_log <- log10(global_range_size_km2)
  
  # Centroid
  centroid <- centroids(target_sp)
  range_centroid_lon <- geom(centroid)[, "x"]
  range_centroid_lat <- geom(centroid)[, "y"]
  
  # 4. EXTRACT RASTER VALUES WITHIN RANGE
  # For percentage rasters (forest, cropland, urban, grassland)
  
  raster_values <- lapply(raster_list, function(y){
  range_raster1_pct <- mean(extract(y, target_sp, 
                               fun = mean, na.rm = TRUE)[, 2])
  })
  
  raster_vals <- data.frame(raster_values)
  
  # 5. CALCULATE OVERLAP WITH EXTINCT SPECIES
  is_extinct <- trait_row$extinct
  
  if (is_extinct == 1) {
    # Extinct species overlaps 100% with itself
    overlap_area_km2 <- global_range_size_km2
    overlap_pct_extinct_range <- 100.0
    overlap_pct_extant_range <- 100.0
  } else {
    # Calculate intersection
    intersection <- intersect(target_sp, extinct_sp)[[1]]
    
    if (is.null(intersection) || nrow(intersection) == 0) {
      # No overlap
      overlap_area_km2 <- 0
      overlap_pct_extinct_range <- 0
      overlap_pct_extant_range <- 0
    } else {
      overlap_area_km2 <- expanse(intersection, unit = "km")
      
      # Calculate percentages
      extinct_range_size <- expanse(extinct_sp, unit = "km")
      overlap_pct_extinct_range <- (overlap_area_km2 / extinct_range_size) * 100
      overlap_pct_extant_range <- (overlap_area_km2 / global_range_size_km2) * 100
    }
  }
  
  # 6. COMPILE RESULTS
  result <- data.frame(
    extinct = is_extinct,
    species_name = species_name,
    
    # Traits
    trait_row,
    
    # Range
    global_range_size_km2 = global_range_size_km2,
    global_range_size_log = global_range_size_log,
    range_centroid_lon = mean(range_centroid_lon),
    range_centroid_lat = mean(range_centroid_lat),
    raster_vals,
    overlap_area_km2 = overlap_area_km2,
    overlap_pct_extinct_range = overlap_pct_extinct_range,
    overlap_pct_extant_range = overlap_pct_extant_range,
    
    stringsAsFactors = FALSE
  )
  
  return(result)
})

caseStudy <- do.call("rbind", caseStudy)

write.csv(caseStudy, here("data", "case_studies", paste0("cs", case_study), "range.based.csv"))



