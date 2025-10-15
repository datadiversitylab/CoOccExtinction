library(here)
library(terra)

# Read in shapefiles
shp_extinct <- list.files(here("data", "case_studies", "cs1", "extinct"),
                        pattern = "\\.shp$",
                        full.names = TRUE)
extinct <- vect(shp_files)


shp_extant <- list.files(here("data", "case_studies", "cs1", "extant"),
                          pattern = "\\.shp$",
                          full.names = TRUE, 
                         recursive = TRUE)
extant <- lapply(shp_extant, vect)

