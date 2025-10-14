# Filtering Delaney's IUCN dataset

##### Amphibians #####

IUCN_full <- read.csv("IUCN_extinct_chordate_taxonomy_and_summary.csv")

# Filter out amphibians
IUCN_amph <- IUCN_full[which(IUCN_full$className == "AMPHIBIA"), ]

# For amphibians, all species in the Indomalayan realm are on islands
IUCN_amph <- IUCN_amph[which(IUCN_amph$realm != "Indomalayan"), ]

# Write final csv for list of species
write.csv(IUCN_amph, "IUCN_amph.csv", row.names = FALSE)


