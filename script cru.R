# Ecological network analysis 
# Developed by Marcio Baldissera Cure
 
library(tidyverse)
library(bipartite)
library(raster)
library(patchwork)
library(RColorBrewer)

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



info1 <- info[-c(133, 139, 140,141,145),] %>%
  select_("Species", "Interactions", "Connectance", "Latitude", "Longitude")


dados <- cbind("Species" = info[-c(133, 139, 140,141,145),] %>%
                 select_("Species"),
               "Interactions" = info[-c(133, 139, 140,141,145),] %>%
                 select_("Interactions") ,
               "Connectance" = info[-c(133, 139, 140,141,145),] %>%
                 select_("Connectance") ,
               robustez_low,
               MAT,
               MAP,
               CV,
               TS,
               PDQ, "Latitude"=info1$Latitude, "Longitude"=info1$Longitude)



info_tropical <- dados %>% 
  filter(Latitude>=-25 & Latitude<=25) %>%
  add_column(Região="Tropical")

info_high_lat <- dados  %>%
  filter(Latitude<-25 & Latitude>25) %>%
  add_column(Região="High latitude")



dados1 <- rbind(info_tropical, info_high_lat)


# write.table(dados1, "dados1.txt")

# Mean annual temperature
MAT.robus <- dados1 %>% ggplot()+
  aes(x=MAT, y=robustez_low, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

MAT.conn <- dados1 %>% ggplot()+
  aes(x=MAT, y=Connectance, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

MAT.inter <- dados1 %>% ggplot()+
  aes(x=MAT, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")


# Mean annual precipitation
MAP.robus <- dados1 %>% ggplot()+
  aes(x=MAP, y=robustez_low, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

MAP.conn <- dados1 %>% ggplot()+
  aes(x=MAP, y=Connectance, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

MAP.inter <- dados1 %>% ggplot()+
  aes(x=MAP, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")

# precipitation seasonality (coefficient of variation)
CV.robus <- dados1 %>% ggplot()+
  aes(x=CV, y=robustez_low, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

CV.conn <- dados1 %>% ggplot()+
  aes(x=CV, y=Connectance, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

CV.inter <- dados1 %>% ggplot()+
  aes(x=CV, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")

# temperature seasonality
TS.robus <- dados1 %>% ggplot()+
  aes(x=TS, y=robustez_low, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

TS.conn <- dados1 %>% ggplot()+
  aes(x=TS, y=Connectance, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

TS.inter <- dados1 %>% ggplot()+
  aes(x=TS, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(Região))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")


# png("/home/marcio/PROJETOS-GIT/redes_ecologicas/métricas_vs_MAT.png", res = 300, width=3000, height = 2400)
# (MAT.robus|MAT.conn|MAT.inter)
# dev.off()
# 
# png("/home/marcio/PROJETOS-GIT/redes_ecologicas/métricas_vs_MAP.png", res = 300, width=3000, height = 2400)
#   (MAP.robus|MAP.conn|MAP.inter)
# dev.off()
# 
# png("/home/marcio/PROJETOS-GIT/redes_ecologicas/métricas_vs_CV.png", res = 300, width=3000, height = 2400)
#   (CV.robus|CV.conn|CV.inter)
# dev.off()
# 
# png("/home/marcio/PROJETOS-GIT/redes_ecologicas/métricas_vs_TS.png", res = 300, width=3000, height = 2400)
#   (TS.robus|TS.conn|TS.inter)
# dev.off()

# png("robus_vs_envir.png", res = 300, width = 2500, height = 2500)
# (MAP.map|MAT.map)/(CV.map|TS.map)
# dev.off()

densidade_rob <- dados1 %>% ggplot() +
  geom_density(aes(x=robustez_low, col = factor(Região), alpha=0.5), show.legend = F)+
  xlab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

densidade_int <- dados1 %>% ggplot() +
  geom_density(aes(x=Interactions %>% log, col = factor(Região), alpha=0.5), show.legend = F)+
  xlab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

densidade_con <- dados1 %>% ggplot() +
  geom_density(aes(x=Connectance, col = factor(Região), alpha=0.5), show.legend = F)+
  xlab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")

# png("densidade.png", res=300, width =3000, height = 2300)
# (densidade_rob|densidade_int|densidade_con)
# dev.off()


### boxplots
box_rob <- dados1 %>% ggplot() +
  geom_boxplot(aes(y=robustez_low, x= factor(Região), fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Robustness")+
  scale_fill_manual(values=c("darkgrey", "orange2"))+
  ggtitle("A")

box_int <- dados1 %>% ggplot() +
  geom_boxplot(aes(y=Interactions %>% log, x= factor(Região),fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Interactions (log)")+
  scale_fill_manual(values=c("darkgrey", "orange2"))+
  ggtitle("B")

box_con <- dados1 %>% ggplot() +
  geom_boxplot(aes(y=Connectance, x=factor(Região), fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Connectance")+
  scale_fill_manual(values=c("darkgrey", "orange2"))+
  ggtitle("C")

png("boxplot_metricas.png", res=300, width = 2300, height = 2000)
(box_rob|box_int|box_con)
dev.off()


t.test(dados1$robustez_low~factor(dados1$Região))
t.test(dados1$Connectance~factor(dados1$Região))
t.test(dados1$Interactions %>% log~factor(dados1$Região))
