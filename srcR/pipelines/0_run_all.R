library(here)
source(here("srcR", "misc", "stack_rasters.R"))
source(here("srcR", "pipelines", "pipeline_species_range.R"))
source(here("srcR", "pipelines", "pipeline_grid_based.R"))
source(here("srcR", "pipelines", "pipeline_cell.R"))

#Set resolution
res <- "20k" #1k, 5k, 10k, and 20k

# Read-in rasters, case-studies, traits
rasters <- stack_rasters(paste0("global_", res,".tif"))
case_studies <- list.dirs(here("data", "case_studies"), recursive = FALSE)
traits <- read.csv(here("data", "traits.csv"))

## Check that traits match species in case studies
shp_files <- list.files(pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
all_species <- unlist(lapply(shp_files, function(f) {
  shp <- vect(f)
  col <- grep("^sci_name$", names(shp), ignore.case = TRUE, value = TRUE)
  if(length(col) > 0) shp[[col[1]]] else NULL
}))
unique_species <- unique(all_species)
missing_species <- setdiff(unique_species, traits$species)

#Run pipelines
pipeline_species_range(case_studies = case_studies, rasters = rasters, traits = traits)
pipeline_cell(case_studies = case_studies, rasters = rasters, traits = traits, ref = paste0("global_", res,".tif"))
pipeline_grid_based(case_studies = case_studies, rasters = rasters, traits = traits, ref = paste0("global_", res,".tif"))



