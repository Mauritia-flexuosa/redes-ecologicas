# Ecological network analysis 
# Developed by Marcio Baldissera Cure
 
library(tidyverse)
library(bipartite)
library(raster)

lista_com_os_dados_baixados <- unzip("./web-of-life_2021-12-01_213658.zip")%>%
  as.list


info <- read.csv(lista_com_os_dados_baixados[1], h = T, row.names = 1) %>%
  select_("Species", "Interactions", "Connectance", "Latitude", "Longitude") 


lista_com_os_dados_baixados <- lista_com_os_dados_baixados[-c(1, 2,135, 141, 142, 143)] 

lista_com_os_dados_baixados %>% length()

lista <- list(NULL)
for (i in 3:140) {
  lista[i] <- lista_com_os_dados_baixados[i] %>% map(read.csv, row.names=1,h=T)  
}

extinção_low <- lista[3:138] %>% 
  map(second.extinct, participant="lower", method="random", nrep=30, details=FALSE) 

# preciso mudar a classe para poder rodar a função do robustness
class(extinção_low)

robustez_low <- extinção_low %>% map(robustness) %>%
  unlist()

robustez_low %>% length()

robust_map <- robustez_low %>% unlist %>% 
 as.data.frame %>% ggplot()+geom_density(aes(x=.))

# png("robustez_low.png", res = 300, width = 2000, height = 2200)
# robust_map
# dev.off()


xy <- data.frame(x=info$Longitude, y=info$Latitude)


MAT <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio1.bil") %>% raster::extract(xy)

MAP <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio12.bil") %>% raster::extract(xy)

CV <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio15.bil") %>% raster::extract(xy) 

TS <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio4.bil") %>% raster::extract(xy) 

PDQ <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio17.bil") %>% raster::extract(xy) 
