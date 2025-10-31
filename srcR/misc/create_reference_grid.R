library(geodata)
library(terra)
library(here)

# 10 minutes (~20 km)
wc_10min <- worldclim_global(var = "bio", res = 10)

# 5 minutes (~10 km)
wc_5min <- worldclim_global(var = "bio", res = 5)

# 2.5 minutes (~5 km)
wc_2.5min <- worldclim_global(var = "bio", res = 2.5)

# 0.5 minutes (~1 km)
wc_30sec <- worldclim_global(var = "bio", res = 0.5)

# Export empty rasters
empty_raster_20km <- wc_10min[[1]]
values(empty_raster_20km) <- NA

writeRaster(empty_raster_20km, 
            filename = here("data", 
                            "spatial_data",
                            "referecence_grids",
                            "global_20k.tif"),
            overwrite = TRUE)

empty_raster_10km <- wc_5min[[1]]
values(empty_raster_10km) <- NA
writeRaster(empty_raster_10km, 
            filename = here("data", 
                            "spatial_data",
                            "referecence_grids",
                            "global_10k.tif"),
            overwrite = TRUE)


empty_raster_5km <- wc_2.5min[[1]]
values(empty_raster_5km) <- NA
writeRaster(empty_raster_5km, 
            filename = here("data", 
                            "spatial_data",
                            "referecence_grids",
                            "global_5k.tif"),
            overwrite = TRUE)

empty_raster_1km <- wc_30sec[[1]]
values(empty_raster_1km) <- NA
writeRaster(empty_raster_1km, 
            filename = here("data", 
                            "spatial_data",
                            "referecence_grids",
                            "global_1k.tif"),
            overwrite = TRUE)


