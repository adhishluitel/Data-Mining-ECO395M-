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
#z_std = scale(z)
z_std = z
mu = attr(z_std,"scaled:center")
sigma = attr(z_std,"scaled:scale")
res <- cor(z_std)
corrplot(res, method = "color", tl.cex = 0.5, tl.col="black")

# distribution plot
xy = subset(wine,select = c("fixed.acidity","chlorides","volatile.acidity","sulphates")) 
#picked these four variables randomly
ggpairs(xy,aes(col = wine$color, alpha = 0.7))


#Clustering
#Start with K means 2 as we have two basic categories (Red/White)
cluster1 = kmeans(z_std, 2, nstart=20)
#Comparing fixed acidity with chlorides first
#nstart=20 because
qplot(wine$fixed.acidity,wine$chlorides, data=wine, shape=factor(cluster1$cluster), col=factor(wine$color))
#Then compare volatile acidity with sulphates
#qplot(wine$volatile.acidity,wine$sulphates, data=wine, shape=factor(cluster1$cluster), col=factor(wine$color))


#Confusion matrix
table1 = xtabs(~cluster1$cluster + wine$color) ###
print(table1)
#accuracy rate K-means=2 is (4,830+1,575)/6,497 = 98.6%. Pretty accurate


#Now, PCA
pca = prcomp(z_std, scale=TRUE)
summary(pca) #note the proportion of variance. PC1-PC3 look pretty significant. 
#Combined they form 0.6436/1 = 64.3% of the total variance in the dataset

loadings = pca$rotation


# PCA for clustering
cluster_pca = kmeans(z_std[,1:4], 2, nstart=20)
qplot(z_std[,1], z_std[,2], color=factor(wine$color), shape=factor(cluster_pca$cluster), xlab='Component 1', ylab='Component 2')

# PCA confusion matrix table
table2 = xtabs(~cluster_pca$cluster + wine$color) 
print(table2)
#accuracy rate K-means=2 is (4,635+938)/6,497 = 82.7%. Pretty accurate but worse than clustering

#But does this technique also seem capable of sorting the higher from the lower quality wines?


###Distinguishing the quality
#First we need to cluster into 7 categories



