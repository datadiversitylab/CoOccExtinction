# Filtering Delaney's IUCN dataset

# IUCN_full <- read.csv("IUCN_extinct_chordate_taxonomy_and_summary.csv")
IUCN_full <- read.csv("IUCN_extinct_chordate_taxonomy_and_summary_1.csv")

##### Amphibians #####

# Filter out amphibians
IUCN_amph <- IUCN_full[which(IUCN_full$className == "AMPHIBIA"), ]

# For amphibians, all species in the Indomalayan realm are on islands
IUCN_amph <- IUCN_amph[which(IUCN_amph$realm != "Indomalayan"), ]

# Write final csv for list of species
write.csv(IUCN_amph, "IUCN_amph.csv", row.names = FALSE)

##### Mammals #####

IUCN_mam <- IUCN_full[which(IUCN_full$className == "MAMMALIA"), ]

# For now, grep for "island" in the range column, then manually inspect
mam_exclude <- IUCN_mam[grep("island", IUCN_mam$range), ]

# CONFIRMED: all species with "island" in the range column should be excluded
# Use -grep
IUCN_mam <- IUCN_mam[-grep("island", IUCN_mam$range), ]

# Some of the remaining species are actually on islands
# Manually select those that aren't
IUCN_mam <- IUCN_mam[c(4,6,8,9,10),]

# Write final csv for list of species
write.csv(IUCN_mam, "IUCN_mam.csv", row.names = FALSE)

##### Birds #####

IUCN_bird <- IUCN_full[which(IUCN_full$className == "AVES"), ]

# Like mammals, grep for "island" in the range column first
bird_exclude <- IUCN_bird[grep("island", IUCN_bird$range), ]

# CONFIRMED: all species with "island" in the range column should be excluded
# Use -grep
IUCN_bird <- IUCN_bird[-grep("island", IUCN_bird$range), ]

# Manually inspect all of them, since the word "island" wasn't comprehensive
inspect <- cbind(IUCN_bird$scientificName, IUCN_bird$range)
write.csv(inspect, "bird_list.csv", row.names = FALSE)

# I realized that removing instances of "Hawai'i" would help
bird_list <- read.csv("bird_list_2.csv") # The second half of bird_list.csv
bird_list <- bird_list[-grep("Hawai'i", bird_list$Range), ]
bird_list <- bird_list[-grep("Hawai`i", bird_list$Range), ]
# All of these birds are from islands, as it turns out

# Kiran filtered the first half of bird_list.csv
bird_list <- read.csv("kcb_bird_list_1.csv")

# Only keep birds that were marked with a "n" in the "island_yn" column
bird_sp <- bird_list[which(bird_list$island_yn == "n"),]

# Grab these species from the IUCN_bird object
sp_list <- bird_sp$V1
IUCN_bird <- IUCN_bird[which(IUCN_bird$scientificName %in% sp_list), ]

# Write final csv for list of species
write.csv(IUCN_bird, "IUCN_bird.csv", row.names = FALSE)

##### Reptiles #####

IUCN_rep <- IUCN_full[which(IUCN_full$className == "REPTILIA"), ]

# Like mammals, grep for "island" in the range column first
rep_exclude <- IUCN_rep[grep("island", IUCN_rep$range), ]

# CONFIRMED: all species with "island" in the range column should be excluded
# Use -grep
IUCN_rep <- IUCN_rep[-grep("island", IUCN_rep$range), ]

# Since it's a small list, simply select the rows with non-island species
IUCN_rep <- IUCN_rep[c(3,10,11),]

# Write final csv for list of species
write.csv(IUCN_rep, "IUCN_reptiles.csv", row.names = FALSE)
