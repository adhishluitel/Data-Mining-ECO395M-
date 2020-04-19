library(tidyverse)
library(LICORS)

social_raw = read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/social_marketing.csv")

summary(social)
length(which(social_raw$spam > 0))
length(which(social_raw$adult > 0))
length(which(social_raw$spam > 0 & social_raw$adult > 0))

social_adult = subset(social_raw, spam == 0)
social_adult$spam = NULL

social_adult = social_adult %>%
  mutate(adultpct = adult/(select(., chatter:adult) %>% rowSums(na.rm = TRUE)))

length(which(social_adult$adultpct >= 0.25))
social = subset(social_adult, 0.25 >= adultpct)

x = social[,(2:36)]
x = scale(x, center = TRUE, scale = TRUE) #subtracting the mean and dividind by the st dev

mu = attr(x,"scaled:center")
sigma = attr(x,"scaled:scale")

clust1 = kmeanspp(x, 4, nstart = 25)

clust1$centers * sigma + mu

colnames(social)
qplot(adult, college_uni, data=social, color=factor(clust1$cluster)) +
  theme_bw()

# Compare versus within-cluster average distances from the first run
clust1$withinss
sum(clust1$withinss)
clust1$tot.withinss
clust1$betweenss