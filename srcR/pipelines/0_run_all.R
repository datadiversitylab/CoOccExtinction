source(here("srcR", "misc", "stack_rasters.R"))
source(here("srcR", "pipelines", "pipeline_species_range.R"))

# Read-in rasters, case-studies, traits
rasters <- stack_rasters("global_1k.tif")
case_studies <- list.dirs(here("data", "case_studies"), recursive = FALSE)
traits <- read.csv(here("data", "traits.csv"))

#Use the species-range pipeline
pipeline_species_range(case_studies = case_studies, rasters = rasters, traits = traits) #Ok