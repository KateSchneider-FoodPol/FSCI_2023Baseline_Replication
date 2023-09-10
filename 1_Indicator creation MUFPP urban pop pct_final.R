rm(list = ls())

setwd("~/projects/urban_food")

### general system packages ###
# install.packages("curl", dependencies = TRUE)
# install.packages("Rcpp", dependencies = TRUE)

### general r packages ###
# install.packages("remotes", dependencies = TRUE)
# install.packages("data.table", dependencies = TRUE)
# install.packages("tidyverse", dependencies = TRUE)
# install.packages("scales", dependencies = TRUE)
# install.packages("units", dependencies = TRUE)
# install.packages("rgl", dependencies = TRUE)
# install.packages("haven", dependencies = TRUE)
# install.packages("readxl", dependencies = TRUE)

### spatial system packages ###
# install.packages("rgdal", dependencies = TRUE)
# install.packages("rgeos", dependencies = TRUE)
# install.packages("s2", dependencies = TRUE)

### foundational spatial packages ###
# install.packages("maptools", dependencies = TRUE)
# install.packages("raster", dependencies = TRUE)
# install.packages("sp", dependencies = TRUE)

### current spatial packages ###
# install.packages("sf", dependencies = TRUE)
# install.packages("terra", dependencies = TRUE)
# install.packages("stars", dependencies = TRUE)
# install.packages("spatstat", dependencies = TRUE)
# install.packages("igraph", dependencies = TRUE)

### spatial applications ###
# install.packages('fasterize', dependencies = TRUE)
# install.packages("exactextractr", dependencies = TRUE)
# install.packages("rmapshaper", dependencies = TRUE)
# install.packages("rosm", dependencies = TRUE)
# install.packages("osmdata", dependencies = TRUE)
# install.packages("sparr", dependencies = TRUE)
# install.packages("ggspatial", dependencies = TRUE)
# install.packages("geojsonR", dependencies = TRUE)
# install.packages("nngeo", dependencies = TRUE)
# install.packages("spatialEco", dependencies = TRUE)
# install.packages("climateStability", dependencies = TRUE)
# install.packages("geodata", dependencies = TRUE)
# remotes::install_github("dieghernan/tidyterra")

# install.packages("ISOcodes", dependencies = TRUE)

### load libraries ###
library(curl)
library(Rcpp)
library(parallel)
###
library(remotes)
library(data.table)
library(tidyverse)
library(scales)
library(units)
library(rgl)
library(haven)
library(readxl)

###
library(rgdal)
library(rgeos)
library(s2)
###
library(maptools)
library(raster)
library(sp)
###
library(sf)
library(terra)
library(stars)
library(spatstat)
library(igraph)
###
library(fasterize)
library(exactextractr)
library(rmapshaper)
library(rosm)
library(osmdata)
library(sparr)
library(ggspatial)
library(geojsonR)
library(spatialEco)
library(climateStability)
library(nngeo)
library(geodata)
library(tidyterra)

library(ISOcodes)
###
sf_use_s2()
sf_use_s2(TRUE)
detectCores()

#### Part I. ####
#### Calculate urban & total pop for all countries with signatories cities ####

### import list of cities and create data frame
mufpp_cities <- read_excel("~/projects/urban_food/data/MUFPP_city_data.xlsx") %>%
  as.data.frame()
mufpp_cities <- mufpp_cities[ ,2:1]

# x <- country_codes() #country names from gadm:: package in order to match
mufpp_cities$country <- gsub("Congo Brazzaville", "Congo", mufpp_cities$country)
mufpp_cities$country <- gsub("Ivory Coast", "Côte d'Ivoire", mufpp_cities$country)
mufpp_cities$country <- gsub("Republic of Congo", "Congo", mufpp_cities$country)

### unique country names list to avoid duplicate extracts per country
mufpp_cities <- mufpp_cities[order(mufpp_cities$country), ]
mufpp_countries <- mufpp_cities$country %>% table() %>% as.data.frame()
names(mufpp_countries) <- c("country", "city_counts")

### MUFPP countries ###
# country_adm0s <- do.call("svc", lapply(mufpp_countries$country, function(x) gadm(country=x, level=0, version="4.0", path=tempdir())))

### all countries ###
w <- world(resolution = 5, level = 0, path=tempdir()) %>% st_as_sf()
country_adm0s <- do.call("svc", lapply(w$GID_0, function(x) gadm(country=x, level=0, path=tempdir())))

#### import landscan global 2020 ####
lsg_world_20 <- rast("~/projects/urban_food/data/landscan-global-2020.tif")
# global(lsg_world_20, "sum", na.rm = TRUE)

#### crop, mask & create list of LSG20 SpatRasters for each country ####
i <- 1
country_SpatRasters <- vector()
while(i <= length(country_adm0s)){
  cntry_crp <- crop(lsg_world_20, country_adm0s[[i]])
  cntry_msk <- mask(cntry_crp, country_adm0s[[i]])
  country_SpatRasters <- c(country_SpatRasters, cntry_msk)
  i <- i + 1
  }

#### use LSG20 SpatRasters to calculate populations for each country ####
i <- 154
countries_urban_pop <- vector()
countries_total_pop <- vector()
while(i <= length(country_adm0s)){
  density_polys <- as.polygons(country_SpatRasters[[i]] > 200) %>% st_as_sf()
  density_polys <- density_polys$geometry %>% st_cast("POLYGON") %>% st_as_sf()
  density_polys <- density_polys %>% mutate(area = as.numeric(st_area(density_polys)))
  density_polys <- density_polys %>% filter(area < max(density_polys$area) - 1)
  density_polys$pops <- exact_extract(country_SpatRasters[[i]], density_polys, fun = 'sum')
  cntry_urbpop <- sum(density_polys$pops)
  countries_urban_pop <- c(countries_urban_pop, cntry_urbpop)
  cntry_totpop <- global(country_SpatRasters[[i]], sum, na.rm = TRUE)[1, ]
  countries_total_pop <- c(countries_total_pop,cntry_totpop)
  i <- i + 1
}

### assemble MUFPP values into data frame ###
country_populations <- data.frame(country = mufpp_countries$country,
                                  Country_Urban_Pop = countries_urban_pop,
                                  Country_Total_Pop = countries_total_pop)

write.csv(country_populations, "~/projects/urban_food/output/cntry_pops.csv")
save(country_populations, file = "~/projects/urban_food/output/cntry_pops.RData")

### assemble all country values into data frame ###

first_part <- data.frame(country = w$NAME_0[1:152],
                         Country_Urban_Pop = countries_urban_pop,
                         Country_Total_Pop = countries_total_pop)

second_part <- data.frame(country = w$NAME_0[154:231],
                         Country_Urban_Pop = countries_urban_pop,
                         Country_Total_Pop = countries_total_pop)

both_parts <- rbind.data.frame(first_part, second_part)

all_country_populations <- both_parts[which(both_parts$Country_Total_Pop != 0), ]

# all_country_populations <- data.frame(country = w$NAME_0,
#                                       Country_Urban_Pop = countries_urban_pop,
#                                       Country_Total_Pop = countries_total_pop)

write.csv(all_country_populations, "~/projects/urban_food/output/all_cntry_pops.csv")
save(all_country_populations, file = "~/projects/urban_food/output/all_cntry_pops.RData")

### save & load objects ###
save(country_SpatRasters, country_populations, file = "~/projects/urban_food/data/FSCI_objects_pt1.RData")
load("~/projects/urban_food/data/FSCI_objects_pt1.RData")

#### Part II. #### This part is still under development ####
#### Identify each signatory city boundary and calculate population ####

### FAO-GADM ADMs for different level polygons ### 

# adm0 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_0")
# writeVector(adm0, "data/GADM/adm0.shp")
adm0 <- vect("~/projects/urban_food/data/GADM/adm0.shp")
# adm1 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_1")
# writeVector(adm1, "data/GADM/adm1.shp")
adm1 <- vect("~/projects/urban_food/data/GADM/adm1.shp")
# adm2 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_2")
# writeVector(adm2, "data/GADM/adm2.shp")
adm2 <- vect("~/projects/urban_food/data/GADM/adm2.shp")
# adm3 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_3")
# writeVector(adm3, "data/GADM/adm3.shp")
adm3 <- vect("~/projects/urban_food/data/GADM/adm3.shp")
# adm4 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_4")
# writeVector(adm4, "data/GADM/adm4.shp")
adm4 <- vect("~/projects/urban_food/data/GADM/adm4.shp")
# adm5 <- vect("~/projects/urban_food/data/gadm_410-levels.gpkg", layer = "ADM_5")
# writeVector(adm5, "data/GADM/adm5.shp")
adm5 <- vect("~/projects/urban_food/data/GADM/adm5.shp")


i <- 205:221
paste(mufpp_cities[i,1], mufpp_cities[i,2], sep = ", ") %>% cbind()

mufpp_cities[which(mufpp_cities$country == "Zambia"), ]$city %>% sort()

adm1[which(adm1$COUNTRY == "South Korea"), ]$NAME_1 %>% sort()
adm2[which(adm2$COUNTRY == "South Korea"), ]$NAME_2 %>% sort()
adm3[which(adm3$COUNTRY == "South Korea"), ]$NAME_3 %>% sort()
adm4[which(adm4$COUNTRY == "Zambia"), ]$NAME_4 %>% sort()
adm5[which(adm5$COUNTRY == "Zambia"), ]$NAME_5 %>% sort()

adm0[grep("*M", adm0$COUNTRY), ]$COUNTRY
adm1[grep("*Lusaka", adm1$NAME_1), ]$NAME_1
adm2[grep("*Lusaka", adm2$NAME_2), ]$NAME_2
adm3[grep("*London", adm3$NAME_3), ]$NAME_3
adm4[grep("*London", adm4$NAME_4), ]$NAME_4
adm5[grep("*Bamako", adm5$NAME_5), ]$NAME_5


mufpp_cities_vect <- adm3[which(adm3$NAME_3 == "Tiranë"), ] 
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Alger"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Luanda"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Buenos Aires"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Córdoba" & adm1$COUNTRY == "Argentina"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Mar del Plata", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Rió Grande"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Rosario" & adm2$COUNTRY == "Argentina"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "San Antonio de Areco"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Melbourne"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Sydney"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Wien"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Brugge"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Bruxelles"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Gent"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Leuven"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Liège"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "La Paz" & adm1$COUNTRY == "Bolivia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Sucre" & adm3$COUNTRY == "Bolivia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Araraquara"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Belo Horizonte"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Curitiba"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Porto Alegre"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Recife"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Rio de Janeiro"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "São Paulo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bobo-Dioulasso"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Ouagadougou"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bamenda 2"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Douala 1"), ] %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Douala 2"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Douala 3"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Douala 4"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Douala 5"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Yaoundé 1"), ] %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 2"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 3"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 4"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 5"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 6"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Yaoundé 7"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Guelph"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Communauté-Urbaine-de-Montréal"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Toronto"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Vancouver"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Sal"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Praia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "N'Djamena"), ][2] %>%
                         terra::union(adm2[which(adm2$NAME_2 == "N'Djamena"), ][1]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Beijing"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Chongqing"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Guangzhou"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Shanghai"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Bogotá D.C."), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Medellin"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Pointe Noire"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Brazzaville"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Santa Ana" & adm2$COUNTRY == "Costa Rica"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Abidjan"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Zagreb"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "København"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Kolding"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Quito"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "San Salvador" & adm1$COUNTRY == "El Salvador"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Addis Abeba"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bordeaux"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Grenoble"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Lyon"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Marseille"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Montpellier" & adm3$COUNTRY == "France"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Montreuil"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm5[which(adm5$NAME_5 == "Mouans-Sartoux"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Nantes" & adm3$COUNTRY == "France"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Paris"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Rennes"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Strasbourg"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Toulouse"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Banjul"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Berlin"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Köln"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Frankfurt am Main"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Accra", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Tamale"), ] %>% 
                         terra::union(adm2[which(adm2$NAME_2 == "Sagnerigu"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Athens" & adm3$COUNTRY == "Greece"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Thessaloniki"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Guatemala"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Tegucigalpa", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Pune"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Bandung"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Surakarta"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Herzliya", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Kfar-Saba", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Ramat Gan", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Tel Aviv"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Ancona"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Aosta"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bari" & adm3$COUNTRY == "Italy"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bergamo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bologna"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Cagliari"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Capannori"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Castel Del Giudice"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Catania"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Chieri"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Cremona" & adm3$COUNTRY == "Italy"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Florence" & adm2$COUNTRY == "Italy"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Foggia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Genova"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Lecco"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Livorno" & adm3$COUNTRY == "Italy"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Lucca"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Milano"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Modena"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Molfetta"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Palermo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Parma"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Lucca"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Roma" & adm3$COUNTRY == "Italy"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Sacile"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Trento"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Torino"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Udine"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Venezia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Kyoto"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Osaka"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Tokyo" & adm1$COUNTRY == "Japan"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Toyama"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Nur-Sultan", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]][1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Nairobi"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Biškek"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Riga"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Antananarivo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Bamako"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Nouakchott"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Guadalajara" & adm2$COUNTRY == "México"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Mérida"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Distrito Federal" & adm1$COUNTRY == "México"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Chişinău"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Ulaanbaatar"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Maputo 1"), ] %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Maputo 2"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Maputo 3"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Maputo 4"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Maputo 5"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Pemba Cidade" & adm3$COUNTRY == "Mozambique"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Cidade De Quelimane" & adm3$COUNTRY == "Mozambique"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Windhoek", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Almere"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Amsterdam"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Ede"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Rotterdam"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "The Hague", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect() %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Utrecht"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Wellington" & adm2$COUNTRY == "New Zealand"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Agadez", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Gaya" & adm3$COUNTRY == "Niger"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Niamey", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Bethlehem, West Bank", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect() %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Chanchamayo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Lima" & adm2$COUNTRY == "Peru"), ] %>% terra::union(adm2[which(adm2$NAME_2 == "Callao" & adm2$COUNTRY == "Peru"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Warszawa"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Funchal (Santa Luzia)"), ] %>% terra::union(adm3[which(adm3$NAME_3 == "Funchal (São Pedro)"), ]) %>% terra::union(adm3[which(adm3$NAME_3 == "Funchal (Sé)"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Torres Vedras (Santa Maria Do Ca"), ] %>% terra::union(adm3[which(adm3$NAME_3 == "Torres Vedras (São Pedro E São T"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Bucharest"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Cheboksary"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Kazan", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]]  %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Moscow City"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Nizhny Novgorod", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Samara", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Dakar"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Ljubljana"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Mogadisho"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "City of Cape Town"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Ethekwini"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "City of Johannesburg"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Daegu"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Seoul"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Wanju"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Yeosu"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Barcelona"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Bilbao"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Cádiz"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Dénia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Donostia-San Sebastián"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Fuenlabrada"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Godella"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Granollers"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Madrid"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Málaga"), ][2])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Ciutadella de Menorca"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Mieres"), ][2])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Montilla"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Oviedo"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Pamplona"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Rivas-Vaciamadrid"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Santiago de Compostela"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Segovia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Sevilla"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Valencia"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Valladolid"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Villanueva de la Cañada"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Vitoria-Gasteiz"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm4[which(adm4$NAME_4 == "Zaragoza"), ][1])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Colombo" & adm2$COUNTRY == "Sri Lanka"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Basel" & adm3$COUNTRY == "Switzerland"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Genève"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Lausanne"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Zürich"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Arusha"), ] %>% terra::union(adm2[which(adm2$NAME_2 == "Arusha Urban"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Bangkok Metropolis"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Carthage"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Tunis"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$GID_2 == "TUR.58.7_1"), ]) #Mezitli
mufpp_cities_vect <- c(mufpp_cities_vect, adm1[which(adm1$NAME_1 == "Dubai"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Birmingham"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Brighton and Hove"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bristol" & adm3$COUNTRY == "United Kingdom"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Glasgow"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm3[which(adm3$NAME_3 == "Bolton" & adm3$COUNTRY == "United Kingdom"), ] %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Bury" & adm3$COUNTRY == "United Kingdom"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Manchester" & adm3$COUNTRY == "United Kingdom"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Oldham" & adm3$COUNTRY == "United Kingdom"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Rochdale" & adm3$COUNTRY == "United Kingdom"), ]) %>% 
                         terra::union(adm3[which(adm3$NAME_3 == "Salford" & adm3$COUNTRY == "United Kingdom"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Stockport" & adm3$COUNTRY == "United Kingdom"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Tameside" & adm3$COUNTRY == "United Kingdom"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Trafford" & adm3$COUNTRY == "United Kingdom"), ]) %>%
                         terra::union(adm3[which(adm3$NAME_3 == "Wigan" & adm3$COUNTRY == "United Kingdom"), ]) %>% aggregate())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Greater London", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Austin", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]][1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Baltimore", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Chicago", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Los Angeles", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Madison", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]][1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Miami", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[1]][1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Minneapolis", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[1]] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "New Haven", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "New Port Richey", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "New York", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]][1,] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Pittsburgh", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[1,] %>% vect())
x <- getbb(place_name = "San Francisco", format_out = "sf_polygon", featuretype = "city", silent = FALSE)[[2]] %>% 
  st_cast("POLYGON") %>% 
  st_cast("LINESTRING") %>% 
  st_cast("POLYGON")
mufpp_cities_vect <- c(mufpp_cities_vect, x[2, ] %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "Washington DC", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, getbb(place_name = "West Sacramento", format_out = "sf_polygon", featuretype = "city", silent = FALSE) %>% vect())
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Kitwe"), ])
mufpp_cities_vect <- c(mufpp_cities_vect, adm2[which(adm2$NAME_2 == "Lusaka"), ])

##### plots of each polygon with OSM basemap ####

i <- 1
while(i <= length(mufpp_cities_vect)){
  ggplot() +
    annotation_map_tile(type = "osm") +
    geom_spatvector(data = mufpp_cities_vect[[i]], alpha = 0, size = 1, color = "red")
  ggsave(plot = last_plot(), filename = paste("output/plots/",i,".png", sep = ""))
  i <- i + 1
  }



##### extract population totals per city ####

lsg_world_20 <- rast("~/projects/urban_food/data/landscan-global-2020.tif")
lsg_world_20_r <- raster("~/projects/urban_food/data/landscan-global-2020.tif")

i <- 1
all_pops <- vector()
while(i <= length(mufpp_cities_vect)){
  pops <- terra::extract(lsg_world_20, mufpp_cities_vect[[i]], fun = 'sum', na.rm = TRUE)[1,2]
  all_pops <- c(all_pops, pops)
  i <- i + 1
}

### assemble values into data frame ###
city_populations <- data.frame(cities = mufpp_cities,
                               city_pop = all_pops)
write.csv(city_populations, "~/projects/urban_food/output/city_pops.csv")
save(city_populations, file = "~/projects/urban_food/output/city_pops.RData")


### save & load objects ###
save(city_populations, file = "~/projects/urban_food/data/FSCI_objects_pt2.RData")
load("~/projects/urban_food/data/FSCI_objects_pt2.RData")