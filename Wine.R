library(tidyverse)
library(LICORS)
library(ISLR)
library(foreach)
library(mosaic)
library(GGally)
library(corrplot)
library(ggplot2)

wine_data <- "https://raw.githubusercontent.com/jgscott/ECO395M/master/data/wine.csv"
wine <- read.csv(url(wine_data))
head(wine)

# Center and scale the data, data visualization
z = wine[,1:11]
z = scale(z, center=TRUE, scale=TRUE)
z_std = scale(z)
z_std = z
mu = attr(z_std,"scaled:center")
sigma = attr(z_std,"scaled:scale")
res <- cor(z_std)


# distribution plot
xy = subset(wine,select = c("fixed.acidity","chlorides","volatile.acidity","sulphates")) 
#picked these four variables randomly
ggpairs(xy,aes(col = wine$color, alpha = 0.7))


#Clustering
#Start with K means 2 as we have two basic categories (Red/White) and 25 starts
cluster1 = kmeans(z_std, 2, nstart=25) 
#Comparing fixed acidity with chlorides 
qplot(fixed.acidity, chlorides, data=wine, color=factor(cluster1$cluster))


#Confusion matrix
table1 = xtabs(~cluster1$cluster + wine$color) ###
print(table1)
#accuracy rate is (4,830+1,575)/6,497 = 98.6%. Pretty accurate

# Using kmeans++ clustering
cluster_kpp = kmeanspp(z_std, k=2, nstart=25)
qplot(fixed.acidity, chlorides, data=wine, color=factor(cluster_kpp$cluster))
#Confusion matrix
table2 = xtabs(~cluster_kpp$cluster + wine$color) ###
print(table2)
#Same as Kmeans clustering. No improvement

#What elements in what cluster?
cluster_kpp$center[1,]*sigma + mu
cluster_kpp$center[2,]*sigma + mu

#Now, PCA
pca = prcomp(z_std, scale=TRUE)
summary(pca) #note the proportion of variance. PC1-PC3 look pretty significant. 
#Combined they form 0.6436/1 = 64.3% of the total variance in the dataset

#loadings = pca$rotation

# PCA for clustering
cluster_pca = kmeans(z_std[,1:3], 2, nstart=25) # Ran k-means with 2 clusters and 25 starts
qplot(z_std[,1], z_std[,2], data=wine, color=factor(cluster_pca$cluster))

# PCA confusion matrix table
table3 = xtabs(~cluster_pca$cluster + wine$color) 
print(table3)
#accuracy rate K-means=2 is (4,635+938)/6,497 = 82.7%. Pretty accurate but worse than clustering


#But does this technique also seem capable of sorting the higher from the lower quality wines?
#Now we have to distinguish the quality of wine. Scale of 1-10, so we have 10 categories
#So we will try to cluster into 10 categories
# kmeans clustering
cluster2 = kmeans(z_std, 10, nstart=25)

#Confusion martix
table4 = xtabs(~cluster2$cluster + wine$quality)
print(table4)

#Density plots
ggplot(wine)+ geom_density(aes(x = cluster2$cluster, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.4)
ggplot(wine)+ geom_density(aes(x = wine$quality, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.4)

# kmeans++ clustering
cluster_kpp2 = kmeanspp(z_std, 7, nstart=25)

#Confusion martix
table4 = xtabs(~cluster_kpp2$cluster + wine$quality)
print(table4)

# Now PCA
pca2 = prcomp(z_std, scale=TRUE)
summary(pca2)
loadings = pca2$rotation
scores = pca2$z_std
# PCA for clustering
cluster_pca1 = kmeans(z_std[,1:4], 10, nstart=25)
qplot(z_std[,1], z_std[,2], data=wine, color=factor(cluster_pca1$cluster), xlab='Component 1', ylab='Component 2')

#Confusion matrix for PCA
table5 = xtabs(~cluster_pca1$cluster + wine$quality)
print(table5)
ggplot(wine)+ geom_density(aes(x = cluster_pca1$cluster, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.5)


