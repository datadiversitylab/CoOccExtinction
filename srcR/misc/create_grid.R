library(terra)

# Read in relevant shapefiles
shp_files <- list.files(".",
                        pattern = "\\.shp$",
                        full.names = TRUE)
shapefiles_list <- lapply(shp_files, vect)

cropped_grid <- function(shapefile_list, cell_size_km = 10) {

    # Project to Mollweide
    crs_moll <- "+proj=moll +lon_0=0 +datum=WGS84 +units=m"
    shapes_proj <- lapply(shapefile_list, function(x) project(x, crs_moll))

    # Combine all shapes
    all_shapes <- do.call(rbind, shapes_proj)

    # Create empty grid with extent
    grid <- rast(ext(all_shapes),
                 resolution = cell_size_km * 1000,
                 crs = crs_moll)

    # Rasterize
    grid <- rasterize(all_shapes, grid, field = 1)

    # Assign sequential cell IDs to cells with values
    valid_cells <- which(!is.na(values(grid)))
    values(grid)[valid_cells] <- 1:length(valid_cells)
                          
    return(grid)
}

grid_simple <- cropped_grid(shapefiles_list, cell_size_km = 10)
