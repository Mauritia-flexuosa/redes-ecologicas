# Developed by Marcio Baldissera Cure

library(raster)
library(tidyverse)

# Tree cover data were downloaded from: Hansen et al (2013) - https://www.science.org/doi/10.1126/science.1244693
# https://storage.googleapis.com/earthenginepartners-hansen/GFC2015/Hansen_GFC2015_treecover2000_20S_050W.tif
# https://storage.googleapis.com/earthenginepartners-hansen/GFC2015/Hansen_GFC2015_treecover2000_10S_050W.tif
# https://storage.googleapis.com/earthenginepartners-hansen/GFC2015/Hansen_GFC2015_treecover2000_00S_040W.tif

# Polinator-plant interactions data were downloaded from the Web of Life database (www.web-of-life.es).


# First the ecological data
lista_com_os_dados_baixados <- unzip("./web-of-life_2021-12-01_213658.zip")

lista_com_os_dados_baixados %>% head

# Some information about the networks

info <- read.csv(lista_com_os_dados_baixados[1], h = T, row.names = 1) %>%select_("Species", "Interactions", "Connectance", "Latitude", "Longitude") 

# Now, tree cover
# Nordeste
hansenNE <- raster::raster("/home/marcio/Downloads/Hansen_GFC2015_treecover2000_00N_040W.tif")

# Sudeste

hansenSE <- raster::raster("/home/marcio/Downloads/Hansen_GFC2015_treecover2000_20S_050W.tif")

# Norte

hansenN <- raster::raster("/home/marcio/Downloads/Hansen_GFC2015_treecover2000_10N_070W.tif")

# Norte 2

hansenN2 <- raster::raster("/home/marcio/Downloads/Hansen_GFC2015_treecover2000_10N_080W.tif")

# Coordinates: Latitude and Longitude
xy <- data.frame(x=info$Longitude, y=info$Latitude)

# Extract tree cover data
list(hansenN, hansenNE, hansenSE, hansenN2) %>% 
map(raster::extract, xy)

# Resulting tree covers extracted for the Brazilian tropical sample plots:

tree_cover <-  data.frame(tree_cover=c(0, 95, 0, 98, 0, 13, 20, 87, 97, 99, 99, 100))

info1 <- 
  info[c(30,31,59,133,134,136,137,138,139,140,141,143),] %>% 
  add_column(tree_cover)

# Explore data

panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- abs(cor(x, y))
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste0(prefix, txt)
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)
  text(0.5, 0.5, txt, cex = cex.cor * r)
}

# All the world (149 samples)
pairs(info, lower.panel = panel.smooth, upper.panel = panel.cor,
      gap=0, row1attop=FALSE)

# Tropical South America (12 samples)
pairs(info1, lower.panel = panel.smooth, upper.panel = panel.cor,
      gap=0, row1attop=FALSE)

plot(y=info1$Latitude, x=info1$Longitude)

# Include precipitation data (from the function raster::getData) 
# Source: https://www.worldclim.org

wc <- getData(name = "worldclim", var = "bio", res = 2.5)

MAT <- raster::extract(wc$bio1, xy) # mean annual temperature
MAP <- raster::extract(wc$bio12, xy) # mean annual precipitatiom
CV <- raster::extract(wc$bio15, xy) # precipitation seasonality (coefficient of variation)
TS <-  raster::extract(wc$bio4, xy) # temperature seasonality (standard deviation * 100)

par(mfrow=c(3,3))
plot(info$Connectance ~ MAP)
plot(info$Connectance ~ MAT)
plot(info$Connectance ~ CV)
plot(info$Connectance ~ TS)

plot(info$Interactions %>% log ~ MAP)
plot(info$Interactions %>% log ~ MAT)
plot(info$Interactions %>% log ~ CV)
plot(info$Interactions %>% log ~ TS)

plot(info$Species %>% log ~ MAP)
plot(info$Species %>% log ~ MAT)
plot(info$Species %>% log ~ CV)
plot(info$Species %>% log ~ TS)

plot(MAT~info$Latitude)
plot(MAP~info$Longitude)
plot(TS~info$Latitude)

dev.off()
