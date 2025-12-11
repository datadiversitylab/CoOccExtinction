library(terra)
library(here)
library(rnaturalearth)

#Find the relevant case studies
dirs <- list.dirs(here("data", "case_studies"))[-1] #Remove the root directory
dirs <- dirs[-grep("extant|extinct" , dirs)] #keep case studies only

#Create a directory to export all maps
dir.create(here("results", "maps"))
path_map <- here("results", "maps")

world <- vect(ne_countries(scale = "medium", returnclass = "sf"))

for(i in seq_along(dirs)){
  
  extinct <- list.files(paste0(dirs[i], "/extinct"), pattern = "shp", full.names = TRUE)
  extant <- list.files(paste0(dirs[i], "/extant"), pattern = "shp", full.names = TRUE)
  extinct_sp <- vect(extinct)
  extant_sp <- vect(extant)
  
  pdf(paste0(path_map, "/", basename(dirs[i]), ".pdf"), paper = "a4r", width = 11, height = 8)
  
  #Page 1: Extinct species
  plot(world, col = "gray95", border = "gray70", main = paste("Extant species:", extinct_sp$SCI_NAME), axes = TRUE)
  plot(extinct_sp, col = "red", alpha = 0.6, add = TRUE)
  
  # Arrow pointing to extinct species
  extinct_centroid <- centroids(extinct_sp)
  extinct_coords <- crds(extinct_centroid)
  arrows(x0 = extinct_coords[1,1] - 10, y0 = extinct_coords[1,2] + 10,
         x1 = extinct_coords[1,1], y1 = extinct_coords[1,2],
         col = "red", lwd = 2, length = 0.15)
  text(extinct_coords[1,1] - 10, extinct_coords[1,2] + 10, 
       labels = "Extinct", pos = 2, col = "red", font = 2, cex = 1.2)
  
  # Page 2: All extant species
  plot(world, col = "gray95", border = "gray70", main = "All extant species", axes = TRUE)
  plot(extant_sp, col = "blue", alpha = 0.6, add = TRUE)
  
  # Page 3: Combined map
  plot(world, col = "gray95", border = "gray70", main = "Extinct and extant species", axes = TRUE)
  plot(extinct_sp, col = "red", alpha = 0.6, add = TRUE)
  plot(extant_sp, col = "blue", alpha = 0.6, add = TRUE)

  # Arrow pointing to extinct species
  extinct_centroid <- centroids(extinct_sp)
  extinct_coords <- crds(extinct_centroid)
  arrows(x0 = extinct_coords[1,1] - 10, y0 = extinct_coords[1,2] + 10,
         x1 = extinct_coords[1,1], y1 = extinct_coords[1,2],
         col = "red", lwd = 2, length = 0.15)
  text(extinct_coords[1,1] - 10, extinct_coords[1,2] + 10, 
       labels = "Extinct", pos = 2, col = "red", font = 2, cex = 1.2)
  
  
  # Individual extant species pages
  for (j in 1:length(extant_sp)) {
    extant_individual <- extant_sp[j]
    plot(world, col = "gray95", border = "gray70", 
         main = paste("Extant species:", extant_individual$sci_name), axes = TRUE)
    plot(extant_individual, col = "blue", alpha = 0.6, add = TRUE)
  }
  
  dev.off()
  
}





