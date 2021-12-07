---
title: "Integrating frameworks: alternative stable states of the global pollination network structure"
---

#### Author: Marcio Baldissera Cure

O objetivo deste documento é apresentar o meu trabalho final da disciplina **Introdução a redes ecológicas - Teoria e Prática**, ministrado pelas professoras [Carine Emer](http://lattes.cnpq.br/2953372411320303) e [Fernanda Costa](http://lattes.cnpq.br/9433727692500645).



### Resumo

Redes ecológicas são uma maneira de representar a estrurura das comunidades em termos de suas interações [Landi et al, 2018](https://doi.org/10.1007/s10144-018-0628-3). Por exemplo, a interação entre polinizadores e plantas é fundamental para a manutenção da biodiversidade e para a emergência de diversos serviços ecossistêmicos, inclusive os de suporte [MEA](https://www.millenniumassessment.org); [IPBES](https://ipbes.net/). As perdas de biodiversidade e as mudanças climáticas, que já ultrapassaram os limites seguros planetários ([Rockström et al, 2009](http://lattes.cnpq.br/9433727692500645)), poderiam impactar de forma irreversível as interações que estruturam os ecossistemas. De acordo com a teoria dos estados alternativos ([Beisner et al 2003](https://esajournals.onlinelibrary.wiley.com/doi/pdf/10.1890/1540-9295%282003%29001%5B0376%3AASSIE%5D2.0.CO%3B2)), sistemas submetidos a mudanças graduais podem responder de forma abrupta e não linear a mudanças ambientais ([Scheffer et al, 2001](https://www.nature.com/articles/35098000)). Dessa forma, eu testo a hipótese de que as métricas que descrevem a estrutura das redes de polinização na região tropical brasileira são sensíveis ao regime climático, assim como é a estrutura da vegetação ([Hirota et al, 2011](https://www.science.org/doi/10.1126/science.1210657)). Sendo assim, é possível testar o efeito das mudanças climáticas nestas redes ao longo de gradientes ambientais e, consequentemente, fazer inferências acerca da resiliência destas interações à mudanças futuras.

Por exemplo, sabe-se que, na região tropical, florestas e savannas são estados alternativos em termos estruturais (i.e. cobertura do dossel) parcialmente determinados pelo regime de precipitação ([Hirota et al, 2011](https://www.science.org/doi/10.1126/science.1210657); [Staver et al, 2011](https://www.science.org/doi/10.1126/science.1210465)). Estados alternativos têm estrutura diferentes, interações diferentes, propriedades emergentes diferentes, ou seja, possuem uma identididade diferente [Scheffer et al 2011](). 

No caso de florestas e savannas, a cobertura do dossel é usada como variável de estado. Em um gradiente ambiental até um certo limiar de condições um estado do sistema domina. A partir dali, o outro estado passaria a dominar. Os dois estados podem ocorrer sob as mesmas condições e isso é devido ao balanço entre os feedbacks positivos e negativos que emergem das interações dentro do sistema.

Eu pensei, entao, que como as redes ecológicas são formas de representar as interações dentro de ecossistemas, a estrutura destas redes poderia refletir a estabilidade em um gradiente de condições ambientais. 

A minha pergunta é: **existem estados alternativos em relação às métricas que definem a estrutura das redes em um gradiente climático?** Ou seja, vamos testar se **existe uma certa estabilidade interrompida abruptamente ao cruzar um certo limiar de condições**.


## Métodos

Os dados de polinização para a região tropical do Brasil foram obtidos a partir do [web-of-life dataset](https://www.web-of-life.es). Os dados climáticos foram obtidos usando a função ```raster::getData``` que busca os dados do [WorldClim](https://www.worldclim.org). Mas você também pode baixar direto do site.

Começa carregando os pacotes necessários:

```
library(tidyverse)
library(bipartite)
library(raster)
```

Unzipa os dados baixados do web-of-life:

```
lista_com_os_dados_baixados <- unzip("./web-of-life_2021-12-01_213658.zip")%>%
  as.list
```

Daí, separei algumas informações (objeto chamado de ```info```) de um dos arquivos baixados que são úteis.

```
info <- read.csv(lista_com_os_dados_baixados[1], h = T, row.names = 1) %>%
  select_("Species", "Interactions", "Connectance", "Latitude", "Longitude")
```


Modificação da lista: retirei uns dados que estavam atrapalhando por alguns motivos.

```
lista_com_os_dados_baixados <- lista_com_os_dados_baixados[-c(1, 2,135, 141, 142, 143)] 
```

Aqui eu leio cada elemento da lista como um arquivo .csv. Note que a classe do objeto ```lista``` continua como lista.

```
lista <- list(NULL)
for (i in 3:140) {
  lista[i] <- lista_com_os_dados_baixados[i] %>% map(read.csv, row.names=1,h=T)  
}
````

Agora, eu pego a lista que eu criei acima e aplico a função ```second.extinct``` para calcular a curva de extinção das plantas (low level) para cada __edge table__ contida nesta lista. Tudo isso coloquei em um objeto chamado de ```extinção_low```.

```
extinção_low <- lista[3:138] %>% 
  map(second.extinct, participant="lower", method="random", nrep=30, details=FALSE) 
```

Agora, finalmente calculamos a robustez que é o cálculo da área abaixo da curva de extinção gerada pela função anterior. Chamei o resultado de ```robustez_low``` e tirei do formato _lista_.

```
robustez_low <- extinção_low %>%
  map(robustness) %>%
  unlist()
  ```

Plotei a densidade de distribuição dos dados usando o pacote ```ggplot2``` contido no pacote ```tidyverse``` para testar (visualmente) por bimodalidade.


```
robust_map <- robustez_low %>% unlist %>% 
 as.data.frame %>% ggplot()+geom_density(aes(x=.))
```

<img width="90%" src="robustez_low.png"/>


Poderia fazer isso para outras funções também, como por exemplo, calcular a especialização complementar h2 como no exemplo abaixo.

```
especialização_complementar_h2 <- lista %>% 
  map(networklevel,index="H2") %>%
  map(data.frame) %>%
  unlist
```

Mas eu não vou fazer isso porque demora muito. :)


Aqui eu uso aquelas outras informações que me interessam que eu chamei lá em cima de ```info```.

Destes dados eu extraio as coordenadas (Longitude e Latitude dos meus dados).


```
xy <- data.frame(x=info$Longitude, y=info$Latitude)
```

#### Agora as variáveis ambientais:

Note que eu já salvei os dados e agora estou simplesmente carregando como raster e extraindo os valores dos pixels correspondentes às nossas coordenadas. Para isso usei o pacote ```raster```.

Dados climáticos:

```
# Temperatura média annual
MAT <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio1.bil") %>% raster::extract(xy)

# Precipitação média anual
MAP <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio12.bil") %>% raster::extract(xy)

# coeficiente de variação da sazonalidade da precipitação
CV <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio15.bil") %>% raster::extract(xy) 

# Sazonalidade da temperatura
TS <- raster("/home/marcio/PROJETOS-GIT/redes/wc/bio4.bil") %>% raster::extract(xy) 

# Precipitação no quartil mais seco.
PDQ <- raster("/home/marcio/PROJETOS-GIT/redes_ecologicas/wc2-5/bio17.bil") %>% raster::extract(xy) 

```

## Resultados:




O próximo passo seria testar estas mesmas métricas, mas separando por:

1. Cobertura do dossel; pra ver de forma simples e generalizada, mas mesmo assim bem frequente e aceita na literatura, se tipos diferentes de vegetação possuem padrões de resposta diferentes.

2. Guildas; pra ver se diferentes guildas possuem padrão de resposta diferentes.



Dúvidas? Entre em contato:

</br>

<footer><p class="small">

<h3>Contatos:</h3>

<div>
<a href = "mailto:marciobcure@gmail.com"><img src="https://img.shields.io/badge/-Gmail-%23333?style=for-the-badge&logo=gmail&logoColor=white" target="_blank"></a>
 <a href="https://instagram.com/marciobcure" target="_blank"><img src="https://img.shields.io/badge/-Instagram-%23E4405F?style=for-the-badge&logo=instagram&logoColor=white" target="_blank"></a>
</div>
</p></footer>
