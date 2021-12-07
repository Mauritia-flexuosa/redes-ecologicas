# Ecological network analysis 
# Developed by Marcio Baldissera Cure
 
library(tidyverse)
library(bipartite)
library(raster)
library(patchwork)

lista_com_os_dados_baixados <- unzip("./web-of-life_2021-12-01_213658.zip")%>%
  as.list

info <- read.csv("./references.csv", h = T, row.names = 1) %>%
  select_("Species", "Interactions", "Connectance", "Latitude", "Longitude") 


lista_com_os_dados_baixados <- lista_com_os_dados_baixados[-c(1, 2,135, 141, 142, 143)] 


lista <- list(NULL)
for (i in 1:144) {
  lista[i] <- lista_com_os_dados_baixados[i] %>%
    map(read.csv, row.names=1,h=T)  
}


extinção_low <- lista[1:144] %>% 
  map(second.extinct,
      participant="lower",
      method="random",
      nrep=30,
      details=FALSE) 

# preciso mudar a classe para poder rodar a função do robustness

robustez_low <- extinção_low %>% map(robustness) %>%
  unlist()


robust_map <- robustez_low %>%
  unlist %>% 
  as.data.frame %>%
  ggplot() +
   geom_density(aes(x=.))

# png("robustez_low.png", res = 300, width = 2000, height = 2200)
# robust_map
# dev.off()

xy <- data.frame(x=info$Longitude[-c(133, 139, 140,141,145)],
                 y=info$Latitude[-c(133, 139, 140,141,145)])



MAT <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio1.bil") %>% raster::extract(xy)

MAP <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio12.bil") %>% raster::extract(xy)

CV <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio15.bil") %>% raster::extract(xy) 

TS <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio4.bil") %>% raster::extract(xy) 

PDQ <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio17.bil") %>% raster::extract(xy) 


# Unir tudo:
 
dados <- cbind(robustez_low,MAT, MAP, CV, TS, PDQ) %>% 
  data.frame

# write.table(dados, "dados.txt")

MAT.map <- dados %>% ggplot()+
  aes(x=MAT, y=robustez_low)+
  geom_point()

MAP.map <- dados %>% ggplot()+
  aes(x=MAP, y=robustez_low)+
  geom_point()

TS.map <- dados %>% ggplot()+
  aes(x=TS, y=robustez_low)+
  geom_point()

CV.map <- dados %>% ggplot()+
  aes(x=CV, y=robustez_low)+
  geom_point()

PDQ.map <- dados %>% ggplot()+
  aes(x=PDQ, y=robustez_low)+
  geom_point()


# png("robus_vs_envir.png", res = 300, width = 2500, height = 2500)
# (MAP.map|MAT.map)/(CV.map|TS.map)
# dev.off()


