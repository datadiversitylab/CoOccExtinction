library(here)
library(terra)
library(dplyr)

pipeline_species_range <- function(case_studies, rasters, traits){
  
  css <- case_studies
  
  lapply(css, function(t_cs){
    # Find the current study's numeric identifier
    css_n <- as.numeric(gsub("\\D", "", t_cs))
    
    # It doesn't follow our case study naming convention, so fix it
    if(css_n < 10){
      # If the number is less than 10, it needs two zeroes
      case_study <- paste0("CS_00", css_n)
    } else {
      # If the number is greater than 10, it needs one zero
      case_study <- paste0("CS_0", css_n)
    }
    
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
    

    # Construct dataset
    full_species <- rbind(extant, extinct)
    caseStudy <- lapply(1:nrow(full_species), function(sp){

      # Target sp is an extant species SpatVector
      target_sp <- full_species[sp]
      
      # Is the extinct species always the last SpatVector?
      extinct_sp <- full_species[length(full_species)]
      
      # Grab the current species name from the SpatVector
      species_name <- sub(" ", "_",  full_species[sp]$sci_name[1])    
      
      # If species_name is na, then it's probably an extinct species
      #  (the scientific name is stored differently in those SpatVectors)
      if(is.na(species_name)){species_name =  sub(" ", "_", extinct$SCI_NAME)}
      
      print(paste("species_name is:", species_name))
      
      # 2. TRAITS (from traits CSV)
      trait_row <- traits %>% filter(species == species_name)
      
      if (nrow(trait_row) == 0) {
        warning(paste("No traits found for", species_name))
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
      # For percentage rasters (forest, cropland, urban)
      raster_values <- lapply(1:dim(rasters)[3], function(y){
        vals <- values(rasters[[y]], mat = FALSE, na.rm = TRUE)
        is_cont <- any(vals != round(vals), na.rm = TRUE)
        if( is_cont ){
          val <- mean(extract(rasters[[y]], target_sp, fun = "mean", na.rm = TRUE)[, 2])
          names(val) <- names(rasters)[y]
          val
        }else{
          a <- crop(rasters[[y]], target_sp)
          a <- mask(a, target_sp)
          val <- 100*expanse(a, unit = "km")[2] / expanse(target_sp, unit = "km")
          names(val) <- names(rasters)[y]
          val
        }
      })

      all_names <- unlist(lapply(raster_values, names))
      all_values <- unlist(lapply(raster_values, as.numeric))
      
      # Create single-row data frame
      raster_values <- as.data.frame(t(all_values))
      colnames(raster_values) <- all_names
      
      
      # 5. CALCULATE OVERLAP WITH EXTINCT SPECIES
      # traits.csv actually just has an "extant" column, where 0 is extinct
      is_extinct <- as.numeric(trait_row$extant[1])
      print(paste("The value of the extant column is:", is_extinct))    
      
      if (is_extinct == 0) {
        # Extinct species overlaps 100% with itself
        overlap_area_km2 <- global_range_size_km2
        overlap_pct_extinct_range <- 100.0
        overlap_pct_extant_range <- 100.0
      } else {
        # Calculate intersection
        intersection <- intersect(extinct_sp, target_sp)[[1]]
        
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
      # Remember: is_extinct is from the "extant" column in traits.csv
      result <- data.frame(
        case_study = case_study,
        extinct_species_group = sub(" ", "_", extinct$SCI_NAME),
        extant = is_extinct,
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
    
    write.csv(caseStudy, here("results", case_study, ".range.based.csv"))
  })
  
}
