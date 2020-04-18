library(ggplot2)
library(foreach)
library(tidyverse)
library(LICORS)
library(cluster)
library(corrplot)

social_marketing <- read.csv("C:/Users/yaint/OneDrive/desktop/data mining/ECO395M-master/data/social_marketing.csv", row.names = 1)
soma<- social_marketing

# Data Cleaning

# Get rid of spam users - Nobody tweets spam messages unless (s)he's a bot
soma<-soma[(soma$spam==0),] # delete observations related to spam
soma <- soma[,-35] # get rid of spam variable

# we also delete variables "chatter" and "uncategorized"
# because the company cannot get any information from these categories
soma<- soma[,-c(1,5)]

# But we cannot delete all the users in adult category because it can be their hobby
# Then how can we distinguish bots from users? 
# We meausure adult ratio 
soma <- cbind(tweet_sum = rowSums(soma), soma)
soma <- cbind(adult_ratio = 1, soma)
soma$adult_ratio <- soma$adult/soma$tweet_sum
summary(soma$adult_ratio)
hist(soma$adult_ratio)

# Though there's no absolute criterion, We'll set 20% as our criterion
# Normal people don't tweet porn in public
# And their other non-adult tweets might lead other users into porn
length(which(soma$adult_ratio>0.2))
length(which(soma$adult_ratio>0.2))/(length(which(soma$adult_ratio>0)))
soma<-soma[(soma$adult_ratio<0.2),]

# Finally delete two variables we've just made -  adult_ratio, tweet_sum
soma <- soma[,-c(1,2)]

# Center and scale the data with 33 variables
soma_sc <- scale(soma, center=TRUE, scale=TRUE)

# Extract the centers and scales from the rescaled data
mu= attr(soma_sc, "scaled:center")
sigma = attr(soma_sc, "scaled:scale")

# Clustering
# K-means or Hierarchical clustering?
# We don't observe any hierarchy in our variables, so we use K-means

# What is the optimal K?
# Elbow plot
k_grid = seq(2,20, by=1)
SSE_grid = foreach(k=k_grid, .combine='c') %do% {cluster_k= kmeanspp(soma_sc, k, nstart=25)
cluster_k$tot.withinss}
plot(k_grid, SSE_grid)#cannot see any elbow here!

# CH index
N=nrow(soma)
CH_grid= foreach(k=k_grid, .combine='c') %do% {
  cluster_k = kmeanspp(soma_sc, k, nstart=25)
  W= cluster_k$tot.withinss
  B= cluster_k$betweenss
  CH= (B/W)*((N-k)/(k-1))
  CH
}
plot(k_grid, CH_grid)# K=2 or 3?

# Gap Statistic
soma_gap = clusGap(soma_sc, FUN= kmeanspp, nstart=25, K.max=10, B=100)
plot(soma_gap) # There is no dip

# corrplot(just for reference)
res <- cor(soma_sc)
corrplot(res, method = "color", tl.cex = 0.5, tl.col="black")

# It's hard to find the optimal K by mathematics.
# Suppose the company divides market segments into three parts
# One to concentrate and imporove, one for maintain current situation, the other for considering giving up

# Now do K-means++ with K=3
clust1 = kmeanspp(soma_sc, k=3, nstart=25)
clust1$center
# In this case, scaled values can give us more information than absolute values
# because we are interested in realtive preference

length(which(clust1$cluster == 1))
length(which(clust1$cluster == 2))
length(which(clust1$cluster == 3))

sort(clust1$centers[1,], decreasing=TRUE)
# interested in religion, parenting, sports_fandom, food, school
# If the numbers are bigger than 1(sted), we'll tell that they are interested in this category

sort(clust1$centers[2,], decreasing=TRUE)
# not interested in anything

sort(clust1$centers[3,], decreasing=TRUE)
# not interested in anything
# This is not a balanced clustering at all, so we do clustering again when k=4

clust2 = kmeanspp(soma_sc, k=4, nstart=25)
clust2$center

length(which(clust2$cluster == 1))
length(which(clust2$cluster == 2))
length(which(clust2$cluster == 3))
length(which(clust2$cluster == 4))

sort(clust2$centers[1,], decreasing=TRUE)
# interested in cooking, health_nutrition, personal_fitness
# We can call this group "Healthy"

sort(clust2$centers[2,], decreasing=TRUE)
# interested in politics, news, travel, computers, automotive
# We can call this group "Intelligent and Active"

sort(clust2$centers[3,], decreasing=TRUE)
# not specially interested in anything 
# We can call this group "Normal"

sort(clust2$centers[4,], decreasing=TRUE)
# interested in religion, parenting and sports_fandom, food, school and family
# We can call this group "Family-oriented"

# Now it seems to be more balanced

# Some example plots
qplot(politics, cooking, data=soma, color=factor(clust2$cluster))
# cluster1: interested in cooking but not in politics
# cluster2: interested in politics but not in cooking
# cluster3 and 4 : not specially interested in both

qplot(health_nutrition, religion, data=soma, color=factor(clust2$cluster))
# cluster1: interested in health_nutrition but not in religion
# cluster2 and 3 : not specially interested in both
# cluster4: interested in religion but not in health_nutrition

qplot(news, parenting, data=soma, color=factor(clust2$cluster))
# cluster1 and 3: not specially interested in both
# cluster2: interested in news but not in parenting
# cluster4: interested in parenting but not in news
