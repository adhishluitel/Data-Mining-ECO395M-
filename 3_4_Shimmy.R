library(ggplot2)
library(foreach)
library(tidyverse)
library(LICORS)
library(cluster)
library(corrplot)
library(GGally)

csocial_marketing <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/social_marketing.csv", row.names = 1)
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
corrplot(res, type = 'lower', method = "color", order = "hclust", hclust.method = "ward.D", tl.cex = 0.5, tl.col="black")

# It's hard to find the optimal K by mathematics.
# Suppose the company divides market segments into three parts
# One to concentrate and imporove, one for maintain current situation, the other for considering giving up


# Method 1: Only K-means++
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

set.seed(12)#set seed in order to get same clusters whenever we try again
clust2 = kmeanspp(soma_sc, k=4, nstart=25)
clust2$center

length(which(clust2$cluster == 1))
length(which(clust2$cluster == 2))
length(which(clust2$cluster == 3))
length(which(clust2$cluster == 4))

sort(clust2$centers[1,], decreasing=TRUE)
# interested in politics, news, travel, computers, automotive
# We can call this group "Intelligent and Active"

sort(clust2$centers[2,], decreasing=TRUE)
# interested in cooking, health_nutrition, personal_fitness
# We can call this group "Healthy"

sort(clust2$centers[3,], decreasing=TRUE)
# interested in religion, parenting and sports_fandom, food, school and family
# We can call this group "Family-oriented"

sort(clust2$centers[4,], decreasing=TRUE)
# not specially interested in anything 
# We can call this group "Normal"

# Now it seems to be more balanced

# Some example plots

Cluster = factor(clust2$cluster)

subset(soma, select = c("family","school","food","sports_fandom","religion","parenting")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
        upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

subset(soma, select = c("computers","travel","politics","news","automotive")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

subset(soma, select = c("outdoors","health_nutrition","personal_fitness")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

subset(soma, select = c("beauty","cooking","fashion")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

subset(soma, select = c("sports_playing","online_gaming","college_uni")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

# cluster1: interested in politics but not in cooking
# cluster2: interested in cooking but not in politics
# cluster3 and 4 : interested in neither one

qplot(health_nutrition, religion, data=soma, color=factor(clust2$cluster))
# cluster2: interested in health_nutrition but not in religion
# cluster3: interested in religion but not in health_nutrition
# cluster1 and 4 : interested in neither one

qplot(news, parenting, data=soma, color=factor(clust2$cluster))
# cluster1: interested in news but not in parenting
# cluster3: interested in parenting but not in news
# cluster2 and 4: not specially interested in both


# Method 2: PCA then K-means++
# Do a principal component analysis first to narrow down our variables and make our model more interpretable

pca= prcomp(soma_sc)#don't need to scale it because we already did
summary(pca)
# We need at least 23 principal components to explain more than 90% of total variables
# So using PCA method is not a good idea here but it can give us some information though

loadings= pca$rotation
scores = pca$x

loadings[,c(1,2)]
o1 = order(loadings[,1], decreasing=TRUE)
colnames(soma_sc)[head(o1,3)]
colnames(soma_sc)[tail(o1,3)]
# pc1: the more interest you have in religion, food, parenting, the more scores you get
#      the less interest you have in college and university, online gaming, porn, the more scores you get
o2 = order(loadings[,2], decreasing=TRUE)
colnames(soma_sc)[head(o2,3)]
colnames(soma_sc)[tail(o2,3)]
# pc2: the more interest you have in sports fandom, religion, parenting, the more scores you get
#      the less interest you have in photo sharing, fashion, cooking, the more scores you get
o3 = order(loadings[,3], decreasing=TRUE)
colnames(soma_sc)[head(o3,3)]
colnames(soma_sc)[tail(o3,3)]
# pc3: the more interest you have in politics, travel, computers, the more scores you get
#      the less interest you have in cooking, personal fitness, health nutrition, the more scores you get
o4 = order(loadings[,4], decreasing=TRUE)
colnames(soma_sc)[head(o4,3)]
colnames(soma_sc)[tail(o4,3)]
# pc4: the more interest you have in health nutrition, personal fitness and outdoors, the more scores you get
#      the less interest you have in sports plaing, online gaming and college and university, the more scores you get

qplot(scores[,1], scores[,2], color=factor(clust2$cluster), xlab='Component1', ylab='Component2')
# cluster1: normal
# cluster2: low pc2 score -> likes photo sharing, fashion, cooking 
#           We already saw that this type likes cooking, which corresponds with our clustering result.
# cluster3: high pc2 score -> likes sports fandom, religion, parenting
#           We already saw that this type likes religion, parenting and sports fandom, which perfectly corresponds with our clustering result.
# cluster4: low pc1 score -> likes college and university, online gaming and porn
#           We don't see these characteristics in our previous clustering analysis.

qplot(scores[,1], scores[,3], color=factor(clust2$cluster), xlab='Component1', ylab='Component3')
# cluster1: high pc3 score -> likes politics, travel, computers
#           It perfectly corresponds with our previous clustering result.
# cluster2,3: normal
# cluster4: low pc1 score -> likes college and university, online gaming and porn
#           We don't observe these characteristic in our previous clustering analysis

qplot(scores[,3], scores[,4], color=factor(clust2$cluster), xlab='Component3', ylab='Component4')
# cluster1: high pc3 score -> likes politics, travel, computers
#           It perfectly corresponds with our previous clustering result.
# cluster2,3,4: normal

# conclustion
# The company needs to establish customized strategies for each cluster group
# e.g. Emphasizing politics and news contents focusing on cluster1 and so on.

colMeans(soma) %>% sort(decreasing=TRUE)
# Besides, Photo sharing, health nutrition, Cooking are top 3 contents that are tweeted
# The company had better more focus on these categories
# But adult, small_business and business tweets are least 3 contents that are tweeted.
# Company can less focus on these categories