library(here)
source(here("srcR", "misc", "stack_rasters.R"))
source(here("srcR", "misc", "match_traits_shp.R"))
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
match_traits_shp(traits = traits)

#Run pipelines
pipeline_species_range(case_studies = case_studies, rasters = rasters, traits = traits) #range
pipeline_cell(case_studies = case_studies, rasters = rasters, ref = paste0("global_", res,".tif")) #cell
pipeline_grid_based(case_studies = case_studies, rasters = rasters, traits = traits, ref = paste0("global_", res,".tif")) #cell x species


