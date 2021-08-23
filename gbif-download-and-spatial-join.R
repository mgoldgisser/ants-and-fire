
library(tidyverse)
library(rgbif) # for occ_download
library(taxize) # for get_gbifid_
library(here)
library(sf)
library(rgdal)
library(raster)
library(rgeos)

user<- "mgoldy"
email <- "marina.goldgisser@gmail.com"
pwd <- "ecoblenderlab"

occ_download(
  pred_or("scientificName","Formicidae"),
  pred_in("basisOfRecord", c('PRESERVED_SPECIMEN', 'MACHINE_OBSERVATION', 'HUMAN_OBSERVATION','OBSERVATION', 'MATERIAL_SAMPLE', 'LITERATURE')),
  pred_within("POLYGON((-123.36768 32.60236,-113.62939 32.60236,-113.62939 38.21401,-123.36768 38.21401,-123.36768 32.60236))"), #this polygon is a square Nborder-SanFran Sborder-mexico E/Wborder-include all CA
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  format = "SIMPLE_CSV",
  user=user,pwd=pwd,email=email
)


# #<<gbif download>> just formicidae
# Username: mgoldy
# E-mail: marina.goldgisser@gmail.com
# Format: SIMPLE_CSV
# Download key: 0002228-210819072339941


#download for both formicidae and Formicariae; use the simple download option
#https://www.gbif.org/occurrence/download/0002227-210819072339941


##need to grab csv data from zip folder download and move to working directory
#may need to open using excel first and then saving as a csv because it downloads as a tab-delim

gbifdata <- read_csv(here("ants", "data", "0002227-210819072339941.csv"))

#remove columns we don't need
gbif <- subset(gbifdata, select = c("verbatimScientificName", "year", "month", "day","decimalLongitude", "decimalLatitude")) %>% 
  rename("species" = "verbatimScientificName") 

#transform to shapefile and add projection
gbif_sf <- st_as_sf(gbif, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326, remove = FALSE)

#save gbif observations as shapefile for later use
st_write(gbif_sf, here("ants", "data", "antsObservations"), driver = "ESRI Shapefile", delete_layer = TRUE)

# add gbif shapefile; this is needed if already converted the gbif csv to shapefile
# gbif_sf <- st_read(here("data", "endangeredplantobs")) 

#add fire shapefile
fire_sf <- st_read(here("ants", "data", "fireshapefile")) %>% 
  st_make_valid(fire_sf)

#not needed, but this transforms the projections so that they are the same
# gbif_sf <- st_transform(gbif_sf, st_crs(fire_sf))

#spatial aggregation: observation points to fire polygons
filter_gbif <- st_filter(gbif_sf, fire_sf, .predicate = st_within)
join_fire_gbif <- st_join(filter_gbif, fire_sf, join = st_within) %>% 
  st_drop_geometry() %>% 
  rename(fireyear = FIRE_YEARn, firename = INCIDENT, firesize = GISAcres)

#counts up multiple instances and generates new vector as counts by grouping factors####
fire_total_obs <- join_fire_gbif %>% 
  group_by(fireID, firename, fireyear, firesize) %>% 
  summarize(n_observations = n()) 

write_csv(fire_total_obs, here("ants", "data", "bronze.csv"))
write_csv(join_fire_gbif, here("ants", "data", "gold2.csv"))


