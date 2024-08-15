# Titulo del script: Trabajo práctico
# Autor:Alan Matheo Morales
# fecha: 2023-12-05
#seccion de librerias que hace uso el script
library(readxl)
library(dplyr)
library(ggplot2)
library(mfx)
library(caret)
library(pROC)
#seccion de borrado o de encerado de variables.
rm(list=ls())
#la logica de script

#---------------------------Pregunta 1
compas_scores <- read_excel("C:/Users/MATHEO/OneDrive - IMF Smart Education/Modulo 3/compas-scores.xlsx")
#Paso2: Seleccionar las variables
names(compas_scores)
compas_scores_temp <- compas_scores[ ,c(1,5,6,8,10,11,12,13,14,15,25,30,34,38,41)]
head(compas_scores_temp)
str(compas_scores_temp) 
glimpse(compas_scores)

summary(compas_scores_temp)
#Imputación simple
tmp1 <- na.omit(compas_scores_select) #No es el mejor método se eliminan el 89% de datos
((nrow(compas_scores_select)-nrow(tmp1))/nrow(compas_scores_select))*100
#Revisión de valores atipicos
fecuencia_valores <- table(compas_scores_temp$is_recid)
#Existen 719 valores con -1, esto valores son eliminados del data frame
compas_scores_temp2 <- subset(compas_scores_temp, is_recid != -1)
compas_scores_temp2 <- as.data.frame(compas_scores_temp2)
summary(compas_scores_temp2)

names(compas_scores_temp2)


#Comprobación de que los NA de las columnas r_offense_date y vr_offense_date corresponden a no incidentes
df_filtrado <- compas_scores_temp2 %>%
  filter(is.na(r_offense_date)) %>%
  select(is_recid) %>%
  unique()

df_filtrado2 <- compas_scores_temp2 %>%
  filter(is.na(vr_offense_date)) %>%
  select(is_violent_recid) %>%
  unique()

fecuencia_compas_screening_date<- table(compas_scores_temp2$decile_score...12)
fecuencia_compas_v_decile_score<- table(compas_scores_temp2$v_decile_score)

#Cambio de valores de -1 a 1 de las variables decile_score y v_decile_score
compas_scores_temp2 <- compas_scores_temp2 %>%
  mutate(decile_score...12 = ifelse(decile_score...12 == -1, 1, decile_score...12))

compas_scores_temp2 <- compas_scores_temp2 %>%
  mutate(v_decile_score = ifelse(v_decile_score == -1, 1, v_decile_score))

summary(compas_scores_temp2)
glimpse(compas_scores_temp2)

#Pasar a factor
compas_scores_temp2$is_recid <- as.factor(compas_scores_temp2$is_recid)
compas_scores_temp2$is_violent_recid <- as.factor(compas_scores_temp2$is_violent_recid)
compas_scores_temp2$race <- as.factor(compas_scores_temp2$race)
summary(compas_scores_temp2)
#Pasar a tipo fecha
compas_scores_temp2$compas_screening_date <- as.Date(compas_scores_temp2$compas_screening_date)
compas_scores_temp2$vr_offense_date <- as.Date(compas_scores_temp2$vr_offense_date)
compas_scores_temp2$r_offense_date <- as.Date(compas_scores_temp2$r_offense_date)
summary(compas_scores_temp2)

#Respuesta pregunta 1
#Al momento de evalaur la la calidad de los datos encontramos que en las principale variables a utilizar: compas_screening_date, decile_score,
#v_decile_score, is_recid, r_offense_date, is_violent_recid y vr_offense_date encontramos que existen problemas de validez en las variables decile_score,
#y v_decile_score. Se encontró que la variable is_recid presentaba valores incosistentes así que se procedió a eliminarlos. Finalmente, se coloca 
#en el formato correcto cada una de las variables seleccionadas.
summary(compas_scores_temp2)

#-----------Pregunta 2

#Correlación de la variables dependiente con las variables explicativas
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$age)
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$priors_count)
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$juv_fel_count)
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$juv_misd_count)
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$juv_other_count)
cor(compas_scores_temp2$decile_score...12,compas_scores_temp2$is_violent_recid)
#Gráfios entre las variables categóricas con la varibles decile score
ggplot(compas_scores_temp2, aes(x = sex, y = decile_score...12, fill = sex)) +
  geom_boxplot() +
  labs(title = "Relación entre 'decile_score...12' y 'sex'",
       x = "Sexo",
       y = "Decile Score...12")

ggplot(compas_scores_temp2, aes(x = race, y = decile_score...12, fill = race)) +
  geom_boxplot() +
  labs(title = "Relación entre 'decile_score...12' y 'raza'",
       x = "raza",
       y = "Decile Score...12")

ggplot(compas_scores_temp2, aes(x = is_recid, y = decile_score...12, fill = is_recid)) +
  geom_boxplot() +
  labs(title = "Relación entre 'decile_score...12' y 'is_recid'",
       x = "is_recid",
       y = "Decile Score...12")

ggplot(compas_scores_temp2, aes(x = is_violent_recid, y = decile_score...12, fill = is_violent_recid)) +
  geom_boxplot() +
  labs(title = "Relación entre 'decile_score...12' y 'is_violent_recid'",
       x = "is_violent_recid",
       y = "Decile Score...12")

names(compas_scores_temp2)

#Para fines prácticos se construye una variable categórica con valores de 1 si el decile score es mayoro igual a 7

compas_scores_temp2$indicador <-  ifelse(compas_scores_temp2$decile_score...12>=7,1,0)
summary(compas_scores_temp2)

#Se realiza la elección del modelo
modelo_datos <- compas_scores_temp2[ ,c("decile_score...12","age","sex","race","priors_count","juv_fel_count",
                                        "juv_misd_count","juv_other_count","is_recid","is_violent_recid", "indicador")]

#Se coloca una semilla
set.seed(123)
indices <- sample( 1:nrow(modelo_datos), nrow(modelo_datos)*0.8)

train_data <- modelo_datos[indices,]
train_data <- modelo_datos[-indices,]

#Modelo de regresión lineal 
modelo <- lm(decile_score...12~.,train_data)
summary(modelo)

#Modelo de regresión logistica sobre la probabilidad de que una perosna tenga un decil score alta
tabla <- table(compas_scores_temp2$indicador)
round(prop.table(tabla),2)*100
modelo_2 <- glm(indicador ~ age + sex + race +priors_count + juv_fel_count + juv_other_count + is_recid + is_violent_recid,
             family=binomial(link = "logit"), data=train_data)
modelo_2 <- logitmfx(indicador ~ age + sex + race +priors_count + juv_fel_count + juv_other_count + is_recid + is_violent_recid, data=train_data)
modelo_2$mfxest

#Respuesta pregunta 2
#La estimación del decile score no se lo puede calcular son con dos variables. En el primer modelo de regresión lineal se utiliza a las variables 
#is_recid y is_violent_recid junto a variables de control como el género, la edad entre otros. Para fines prácticos se contruyó la variable indicador
#para colocar como otra variable de control y aumentar el r cuadrado del modelo (0.77). Sin embargo, el modelo presenta problemas de multicolinealidad.

#El segundo modelo que se aplicó es una regresión logistica que toma como variable dependiente el valor de 1 si el decile score e mayor o igual 7.
#Se mantienen las mismas variables de control y se obtienen los efectos marginales de todas las varibles.

#--------------------Pregunta 3
pred <- predict(modelo_2, train_data) #Se debe aplicar sobre el modelo_2 cuando se obtienen las magnitudes de las variables
tab.pred <- table(pred>0.5,train_data$indicador)
roc1 <- roc(train_data$indicador, pred)
plot(roc1, main = "Curva ROC", col = "blue", lwd = 2)

#Respuesta Pregunta 3
#Para la olbtención de las tablas de contigencia se obtienen las predicciones sobre el modelo_2. Se observa que la especificidad es muy alta 
#y la sensibilidad baja, este problema se lo puede solucionar buscando un punto diferente de corte. Sin embargo, el área bajo la curva es bueno.
#Sensibilidad: 170/(170+406) = 0.29
#Especificidad: 1590/(1590+42) = 0.97
#Tasa de falsos positivos: 0.71
#Precisión: 170/(170+42) = 0.80
#Exactitud: (170+1590)/(170+42+406+1590) = 0.80
#F-score: 0.43

#--------------Pregunta 4
compas_scores_temp2$sex <- as.factor(compas_scores_temp2$sex)

ggplot(compas_scores_temp2, aes(x = factor(decile_score...12), fill = sex)) +
  geom_bar(position = "dodge", color = "black", stat = "count") +
  labs(title = "Distribución de Hombres y Mujeres por Decile Score",
       x = "Decile Score",
       y = "Conteo") +
  scale_fill_manual(values = c("blue", "pink")) 
  theme_minimal()

#Al analizar el gráfico del decile score por género se evidencia que los hombres en cada nivel del decile score es superior al de las mujeres.

glimpse(compas_scores_temp2$race)

ggplot(compas_scores_temp2, aes(x = factor(decile_score...12), fill = factor(decile_score...12), color = factor(decile_score...12))) +
  geom_bar(position = "dodge", stat = "count") +
  facet_wrap(~race, scales = "free_y", ncol = 2) +
  labs(title = "Distribución de Decile Score por Raza",
       x = "Decile Score",
       y = "Conteo") +
  scale_fill_manual(values = rainbow(10)) +  # Colores para decile_score
  scale_color_manual(values = rainbow(10)) +
  theme_minimal()
#Al analizar la distribución del decile score por raza se observa que en los afroamericanos existe un mayor decile score en todas las categorías.

#-----------------Pregunta 5
compas_scores_temp3 <- compas_scores_temp2
compas_scores_temp3$indicador2 <-  ifelse(compas_scores_temp3$v_decile_score>=7,1,0)

modelo_datos_2 <- compas_scores_temp3[ ,c("v_decile_score","age","sex","race","priors_count","juv_fel_count",
                                        "juv_misd_count","juv_other_count","is_recid","is_violent_recid", "indicador2")]

set.seed(256)
indices2 <- sample( 1:nrow(modelo_datos_2), nrow(modelo_datos_2)*0.8)

train_data_2 <- modelo_datos_2[indices2,]
train_data_2 <- modelo_datos_2[-indices2,]

tabla_2 <- table(compas_scores_temp3$indicador2)
round(prop.table(tabla_2),2)*100

modelo_3 <- glm(indicador2 ~ age + sex + race +priors_count + juv_fel_count + juv_other_count + is_recid + is_violent_recid,
                family=binomial(link = "logit"), data=train_data_2)
modelo_3 <- logitmfx(indicador2 ~ age + sex + race +priors_count + juv_fel_count + juv_other_count + is_recid + is_violent_recid, data=train_data_2)
modelo_3$mfxest

pred2 <- predict(modelo_3, train_data_2)
tab.pred_2 <- table(pred2>0.5,train_data_2$indicador2)
roc2 <- roc(train_data_2$indicador2, pred2)
plot(roc2, main = "Curva ROC", col = "red", lwd = 2)

#Respuesta pregunta 5
#Al analizar el área bajo la curva se obtiene que el modelo que toma como variable dependiente a v_decile_score tiene una mayor precisió.


