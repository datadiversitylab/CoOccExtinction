library(terra)

match_traits_shp <- function(traits){
  shp_files <- list.files(pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
  all_species <- unlist(lapply(shp_files, function(f) {
    shp <- vect(f)
    col <- grep("^sci_name$", names(shp), ignore.case = TRUE, value = TRUE)
    if(length(col) > 0) shp[[col[1]]] else NULL
  }))
  unique_species <- unique(all_species)
  missing_species <- setdiff(unique_species, traits$species)
  
  if(length(missing_species) != 0){
    cat("Please check the trait dataset")
    return(missing_species)
  }else{
    cat("All the species ranges have a corresponding entry in the trait dataset")
  }
}
