library(terra)
library(geodata)
library(here)

foot <- footprint(year=2009) 
writeRaster(foot, here("data", "spatial_data", "human.footprint.1993.30s.Venter.tif"))
