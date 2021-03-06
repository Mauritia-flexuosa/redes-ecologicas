# Ecological network analysis 
# Developed by Marcio Baldissera Cure

library(tidyverse)
library(bipartite)
library(raster)
library(patchwork)
library(RColorBrewer)
library(vegan)
library(factoextra)


lista_com_os_dados_baixados <- unzip("./web-of-life_2021-12-01_213658.zip")%>%
  as.list

info <- read.csv("/home/marcio/PROJETOS-GIT/redes_ecologicas/references.csv", h = T, row.names = 1) %>%
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

# Gráficos para explorar por bimodalidade nas distribuições

bi_rob <- dd %>% ggplot(aes(x=robustez_low)) +
  geom_histogram(alpha=0.5, show.legend = F,binwidth = .01)+
  geom_density(aes(alpha=.7, color = factor(cluster)), show.legend = F)+
  xlab("Robustness")+
  scale_fill_manual(values=c("purple2"))+
  ggtitle("Robustness")

bi_int <- dd %>% ggplot(aes(x=Interactions %>% log)) +
  geom_histogram(alpha=0.5, show.legend = F,binwidth = 0.1)+
  geom_density(aes(alpha=.7, color = factor(cluster)), show.legend = F)+
  xlab("Number of interactions (log)")+
  scale_fill_manual(values=c("purple2"))+
  ggtitle("Interactions")

bi_con <- dd %>% ggplot(aes(x=Connectance)) +
  geom_histogram(alpha=0.5, show.legend = F, binwidth = .01)+
  geom_density(aes(alpha=.7, color = factor(cluster)), show.legend = F)+
  xlab("Connectance")+
  scale_fill_manual(values=c("purple2"))+
  ggtitle("Connectance")



# png("/home/marcio/PROJETOS-GIT/redes1/bi_rob.png", res = 300, width = 2400, height = 2000)
# (bi_rob/bi_int/bi_con)
# dev.off()

# Clusterização por K-means

dados_std <- dados1 %>%
dplyr::select("Interactions", "robustez_low", "Species", "Connectance") %>% 
  decostand(method = "standardize")

# Para determinar o número ótimo de clusters
cluster <- fviz_nbclust(dados_std, FUNcluster = kmeans, method = "wss")+
  geom_vline(xintercept = 5, "dashed", color="darkgrey")

png("/home/marcio/PROJETOS-GIT/redes1/cluster_choice.png")
cluster
dev.off()

# Realizando a clusterização por k-means

set.seed(123)
km.res <- kmeans(dados_std, 5, nstart = 25)
print(km.res)

aggregate(dados1 %>%
            dplyr::select("Interactions", "robustez_low", "Species", "Connectance") %>% 
            decostand(method = "standardize"), by=list(cluster=km.res$cluster), mean)

dd <- cbind(dados1, cluster = km.res$cluster)
head(dd)

?fviz_cluster
clusclus <- fviz_cluster(km.res,
             dados1 %>%
               dplyr::select("Interactions", "robustez_low", "Species", "Connectance"),
             ellipse.type = "norm",
             geom = "point")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))

png("/home/marcio/PROJETOS-GIT/redes1/cluster_pca.png", res=300, width = 2400, height = 2000)
clusclus
dev.off()

# PCA

PCA <- dados1 %>%
  dplyr::select("Interactions", "Connectance", "robustez_low", "Species") %>%
  vegan::decostand(method = "standardize") %>%
  prcomp 

PCA %>% summary
# Eigenvalues

PC1 <- PCA %>% 
  broom::tidy() %>%
  dplyr::filter(PC==1) %>%
  dplyr::select("value")

PC2 <- PCA %>% 
  broom::tidy() %>%
  dplyr::filter(PC==2) %>%
  dplyr::select("value")

dados_pca <- data.frame(PC1 = PC1$value, PC2 = PC2$value)

# Eigenvetors
PCA$rotation[,1] %>%
  broom::tidy() %>% 
  rename(variables = names, PC1 = x) %>% 
  knitr::kable()

PCA$rotation[,2] %>%
  broom::tidy() %>% 
  rename(variables = names, PC2 = x) %>% 
  knitr::kable()

# Loadings
PCA %>% plot

# Biplot


loadings <- as.data.frame(PCA$rotation)
scores <- as.data.frame(PCA$x)
label <- rownames(loadings)

# Faz um biplot
pca_plot <- ggplot()+
  geom_point(data = dados_pca, aes(x=PC1, y=PC2, color=factor(dd$cluster)), show.legend = F)+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  geom_segment(data = loadings, aes(x=0,y=0,xend=10*PC1,yend=10*PC2, alpha = 0.5),
                                                                                               arrow=arrow(length=unit(0.7,"cm")), show.legend = F, color = "red")+
  geom_text(data = loadings, aes(x=10*PC1, y=10*PC2, label = label),color="black", size = 4, nudge_x = 0.03, nudge_y = 0.04)+
  xlab("PC1 (51.77 %)")+
  ylab("PC2 (31.6 %)")+ggtitle("PCA of the network metrics")

# png("/home/marcio/PROJETOS-GIT/redes1/pca_metricas.png", res = 300, width = 2500, height = 2100)
# pca_plot
# dev.off()


pc_mat <-     ggplot()+
  aes(x=dd$MAT, y=dados_pca$PC1, alpha=0.6, color=factor(dd$cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("PC1")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("A")

pc_map <-     ggplot()+
  aes(x=dd$MAP, y=dados_pca$PC1, alpha=0.6, color=factor(dd$cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("PC1")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("B")

pc_cv <-     ggplot()+
  aes(x=dd$CV, y=dados_pca$PC1, alpha=0.6, color=factor(dd$cluster))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("PC1")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("C")

pc_ts <-     ggplot()+
  aes(x=dd$MAT, y=dados_pca$PC1, alpha=0.6, color=factor(dd$cluster))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("PC1")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("D")


png("/home/marcio/PROJETOS-GIT/redes1/pc_envir.png", res=300, width = 3000, height = 2600)
(pc_mat|pc_map)/(pc_cv|pc_ts)
dev.off()


# Mean annual temperature
MAT.robus <- dd %>% ggplot()+
  aes(x=MAT, y=robustez_low, size=Species, alpha=0.6, color=factor(dd$cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("A")

MAT.conn <- dd %>% ggplot()+
  aes(x=MAT, y=Connectance, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("B")

MAT.inter <- dd %>% ggplot()+
  aes(x=MAT, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual temperature")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("C")


# Mean annual precipitation
MAP.robus <- dd %>% ggplot()+
  aes(x=MAP, y=robustez_low, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("A")

MAP.conn <- dd %>% ggplot()+
  aes(x=MAP, y=Connectance, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("B")

MAP.inter <- dd %>% ggplot()+
  aes(x=MAP, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Mean annual precipitation")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("C")

# precipitation seasonality (coefficient of variation)
CV.robus <- dd %>% ggplot()+
  aes(x=CV, y=robustez_low, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("A")

CV.conn <- dd %>% ggplot()+
  aes(x=CV, y=Connectance, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("B")

CV.inter <- dd %>% ggplot()+
  aes(x=CV, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Precipitation seasonality (cv)")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("C")

# temperature seasonality
TS.robus <- dd %>% ggplot()+
  aes(x=TS, y=robustez_low, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("A")

TS.conn <- dd %>% ggplot()+
  aes(x=TS, y=Connectance, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("B")

TS.inter <- dd %>% ggplot()+
  aes(x=TS, y=Interactions %>% log, size=Species, alpha=0.6, color=factor(cluster))+
  geom_point(show.legend = F)+
  xlab("Temperature seasonality")+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+  ggtitle("C")


 png("/home/marcio/PROJETOS-GIT/redes1/métricas_vs_MAT.png", res = 300, width=3000, height = 2400)
 (MAT.robus|MAT.conn|MAT.inter)
 dev.off()
# 
# png("/home/marcio/PROJETOS-GIT/redes1/métricas_vs_MAP.png", res = 300, width=3000, height = 2400)
#   (MAP.robus|MAP.conn|MAP.inter)
# dev.off()
#
# png("/home/marcio/PROJETOS-GIT/redes1/métricas_vs_CV.png", res = 300, width=3000, height = 2400)
#   (CV.robus|CV.conn|CV.inter)
# dev.off()
# 
# png("/home/marcio/PROJETOS-GIT/redes1/métricas_vs_TS.png", res = 300, width=3000, height = 2400)
#   (TS.robus|TS.conn|TS.inter)
# dev.off()

png("robus_vs_envir.png", res = 300, width = 2500, height = 2500)
(MAP.map|MAT.map)/(CV.map|TS.map)
dev.off()

densidade_rob <- dd %>% ggplot() +
  geom_density(aes(x=robustez_low, col = factor(cluster), alpha=0.5), show.legend = F)+
  xlab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("A")

densidade_int <- dd %>% ggplot() +
  geom_density(aes(x=Interactions %>% log, col = factor(c.uster), alpha=0.5), show.legend = F)+
  xlab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("B")

densidade_con <- dd %>% ggplot() +
  geom_density(aes(x=Connectance, col = factor(cluster), alpha=0.5), show.legend = F)+
  xlab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("C")

png("/home/marcio/PROJETOS-GIT/redes1/densidade.png", res=300, width =3000, height = 2300)
(densidade_rob|densidade_int|densidade_con)
dev.off()



### boxplots
box_rob <- dd %>% ggplot() +
  geom_boxplot(aes(y=robustez_low, x= factor(cluster), fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Robustness")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("A")

box_int <- dd %>% ggplot() +
  geom_boxplot(aes(y=Interactions %>% log, x= factor(cluster),fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Interactions (log)")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("B")

box_con <- dd %>% ggplot() +
  geom_boxplot(aes(y=Connectance, x=factor(cluster), fill = factor(Região), alpha=0.5), show.legend = F)+
  ylab("Connectance")+
  scale_color_manual(values=c("darkgrey", "orange2", "black", "brown", "blue"))+
  ggtitle("C")

png("/home/marcio/PROJETOS-GIT/redes1/boxplot_metricas.png", res=300, width = 2300, height = 2000)
(box_rob|box_int|box_con)
dev.off()

