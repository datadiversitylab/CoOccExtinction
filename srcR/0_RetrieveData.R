library(here)
options(timeout = 1000)

download.file("https://nextcloud.datadiversitylab.synology.me/s/SKoaW6icqa9K5Lb/download",
              destfile = here("data", "case_studies.zip"))

download.file("https://nextcloud.datadiversitylab.synology.me/s/89454xxfJZWPZBH/download",
              destfile = here("data", "spatial_data", "raster.zip"))