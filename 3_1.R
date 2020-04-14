library(gamlr)
library(tidyverse)
library(kableExtra)
library(randomForest)
library(gbm)

greenbuildings <- read.csv("C:/Users/yaint/OneDrive/desktop/data mining/exercises/hw3/greenbuildings.csv")

# data cleaning
colSums(is.na(greenbuildings))
grb= na.omit(greenbuildings)# find missing values and get rid of them
grb$size = grb$size/1000 # lower the scale of size in order to get around limits of computation
# We see an error occurs when doing a lasso regression if we don't lower the scale


# Make a base model and use stepwise selection
# delete CS_PropertyID because it is nothing but a variable for identification numbers
# delete total_dd_07 because of collinearity(total_dd_07 = cd_total_07 + hd_total07)
# delete cluster because it is recognized as a numerical variable though it is a categorical variable
base_model = lm(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster), data=grb)
full = lm(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster)^2, data=grb)
null = lm(Rent~1, data=grb)

# Forward Selection
system.time(fwd <- step(null, scope=formula(full), dir= "forward"))
length(coef(fwd))
# AIC 34512.51, 50 variables, elapsed time 36 sec

# Backward Selection
system.time(back <- step(full, dir="backward"))
length(coef(back))
# AIC 34372.28(the lowest!), 84 variables, elapsed time 13 min 58 sec

system.time(stepwise <- step(base_model, scope= list(lower=null, upper=full), dir='both'))
length(coef(stepwise))
# AIC 34407.55, 68 variables, elapsed time 3 min 5 sec

v <- c('AIC', 'Variables', 'Elapsed Time')
Forward_selection <- c(34512.51, 50, '36sec')
Backward_selection <- c(34372.28, 84, '13min 58sec')
Stepwise_selection <- c(34407.55, 68, '3min 5sec')
stepwise_result = data.frame(v, Forward_selection, Backward_selection, Stepwise_selection)

kable(stepwise_result) %>% kable_styling("striped")

# Pick the backward selection model as our best model
model1 = lm(Rent ~ size + empl_gr + leasing_rate + stories + age + renovated + 
               class_a + class_b + green_rating + net + amenities + cd_total_07 + 
               hd_total07 + Precipitation + Gas_Costs + Electricity_Costs + 
               cluster_rent + size:leasing_rate + size:stories + size:age + 
               size:renovated + size:class_a + size:class_b + size:cd_total_07 + 
               size:hd_total07 + size:Electricity_Costs + size:cluster_rent + 
               empl_gr:age + empl_gr:class_b + empl_gr:Gas_Costs + leasing_rate:cd_total_07 + 
               leasing_rate:hd_total07 + leasing_rate:Precipitation + leasing_rate:Gas_Costs + 
               leasing_rate:Electricity_Costs + leasing_rate:cluster_rent + 
               stories:age + stories:renovated + stories:class_a + stories:class_b + 
               stories:amenities + stories:cd_total_07 + stories:Precipitation + 
               stories:Electricity_Costs + stories:cluster_rent + age:class_a + 
               age:class_b + age:green_rating + age:cd_total_07 + age:hd_total07 + 
               age:cluster_rent + renovated:cd_total_07 + renovated:hd_total07 + 
               renovated:Precipitation + renovated:Gas_Costs + renovated:Electricity_Costs + 
               renovated:cluster_rent + class_a:amenities + class_a:cd_total_07 + 
               class_a:hd_total07 + class_a:Precipitation + class_a:Gas_Costs + 
               class_a:Electricity_Costs + class_b:cd_total_07 + class_b:hd_total07 + 
               class_b:Precipitation + class_b:Gas_Costs + class_b:Electricity_Costs + 
               green_rating:amenities + net:cd_total_07 + net:cluster_rent + 
               amenities:Precipitation + amenities:Gas_Costs + amenities:Electricity_Costs + 
               amenities:cluster_rent + cd_total_07:Gas_Costs + cd_total_07:Electricity_Costs + 
               hd_total07:Precipitation + hd_total07:Gas_Costs + hd_total07:Electricity_Costs + 
               Precipitation:Gas_Costs + Precipitation:Electricity_Costs + 
               Electricity_Costs:cluster_rent, data=grb)

# Do additional stepwise selection based on model1
step(model1, scope = list(lower= null, upper=full), dir="both")
# No more progress! so we can say model1 is the best model when we use a stepwise selection

# Now do K-fold cross validation to check RMSE when K=10

# Create a vector of fold indicators
N=nrow(grb)
K=10
fold_id = rep_len(1:K, N) # repeats 1:K over and over again
fold_id = sample(fold_id, replace = FALSE) # permute the order randomly

# split train and test set and calculate RMSE for the stepwise selection model
err_save = rep(0, K)
for(i in 1:K){
  train_set = which(fold_id != i)
  y_test = grb$Rent[-train_set]
  model1_train = lm(model1, data=grb[train_set,])
  yhat_test = predict(model1_train, newdata = grb[-train_set,])
  err_save[i] = mean((y_test-yhat_test)^2)
}
#RMSE
sqrt(mean(err_save))#RMSE for our stepwise selection model: 9.100184

# Now we are doing lasso regression.

grb_x = sparse.model.matrix(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster)^2, data=grb)[, -1]
grb_y = grb$Rent
grblasso = gamlr(grb_x, grb_y)
plot(grblasso) 

min(AICc(grblasso))
which.min(AICc(grblasso))
# Among all the segments, 100th segment has the lowest AICc value(34644.64)
min(AIC(grblasso))
# In order to directly compare the lasso model's performance with our stepwise selection model, We find the lowest AIC value our lasso model has. 
# We see that the performance of stepwise model is better in terms of AIC
# stepwise : 34372.28 vs lasso : 34644.64(I didn't write this up on our rmd)

plot(grblasso$lambda, AICc(grblasso))
plot(log(grblasso$lambda), AICc(grblasso))

# the coefficients at the AIC-optimizing value
# note the sparsity
grb_beta = coef(grblasso) 
grb_beta
# optimal lambda
log(grblasso$lambda[which.min(AICc(grblasso))])
sum(grb_beta!=0) # chooses 25 (+intercept) @ log(lambda) = -2.17

p1 <- dimnames(grb_beta)[[1]]
p1
p2 <- c()
p2
for (i in c(1:length(grb_beta))){
  p2 <- c(p2, as.list(grb_beta)[[i]])
}
model2 = c("Rent ~ ")
for (i in c(2:length(grb_beta))){
  if (p2[i] != 0){
    if (model2 == "Rent ~ "){
      model2 = paste(model2, p1[i])
    }
    else{
      model2 = paste(model2,"+", p1[i])
    }
  }
}
model2 <- as.formula(model2)
model2 = lm(model2, data=grb)




# Now calculate RMSE for the lasso model
err_save2 = rep(0, K)
for(i in 1:K){
  train_set2 = which(fold_id != i)
  y_test2 = grb$Rent[-train_set2]
  model2_train = lm(model2, data=grb[train_set2,])
  yhat_test2 = predict(model2_train, newdata = grb[-train_set2,])
  err_save2[i] = mean((y_test2-yhat_test2)^2)
}
#RMSE
sqrt(mean(err_save2))#RMSE for our stepwise selection model: 9.188961



# tree- bagging with K-fold validation
err_save3 = rep(0, K)
system.time(for(i in 1:K){
  train_set3 = which(fold_id != i)
  y_test3 = grb$Rent[-train_set3]
  model3_train = randomForest(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster), data=grb[train_set3,], mtry = 17, ntree=300)
  yhat_test3 = predict(model3_train, newdata = grb[-train_set3,])
  err_save3[i] = mean((y_test3-yhat_test3)^2)
})

#RMSE
sqrt(mean(err_save3))
#RMSE for our bagging model: 6.487657, elapsed time 7 min 26 sec


plot(model3_train) # It seems that 300 ntrees are enough!
varImpPlot(model3_train)
# We also can see that cluster_rent, size, age are the prominent variables which affects Rent.

# tree-Random Forest with K-fold validation

err_save4 = rep(0, K)
system.time(for(i in 1:K){
  train_set4 = which(fold_id != i)
  y_test4 = grb$Rent[-train_set4]
  model4_train = randomForest(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster), data=grb[train_set4,], ntree=300)
  yhat_test4 = predict(model4_train, newdata = grb[-train_set4,])
  err_save4[i] = mean((y_test4-yhat_test4)^2)
})
model4_train
#RMSE
sqrt(mean(err_save4))
#RMSE for our randomforest model: 6.188415, elapsed time 2 min 41sec

plot(model4_train)
# 300 ntrees are enough!
varImpPlot(model4_train)

# tree-Boosting with K-fold validation

err_save5 = rep(0, K)

system.time(for(i in 1:K){
  train_set5 = which(fold_id != i)
  y_test5 = grb$Rent[-train_set5]
  model5_train <- gbm(Rent~(.-CS_PropertyID-LEED-Energystar-total_dd_07-cluster), data=grb[train_set5,], interaction.depth=4, n.trees = 100, shrinkage =.05)
  yhat_test5 = predict(model5_train, newdata = grb[-train_set5,], n.trees = 300)
  err_save5[i] = mean((y_test5-yhat_test5)^2)
})

#RMSE
sqrt(mean(err_save5))
#RMSE for our boosting model: 8.217681, elapsed time 15 sec

summary(model5_train)
# 'Cluster_rent' variable turns out to be the on which reduces the MSE most.


Model <- c('Stepwise', 'Lasso','Bagging','Randomforest','Boosting')
RMSE <- c(round(sqrt(mean(err_save)),2), round(sqrt(mean(err_save2)),2),round(sqrt(mean(err_save3)),2),round(sqrt(mean(err_save4)),2),round(sqrt(mean(err_save5)),2))
RMSE_result = data.frame(Model,RMSE)
RMSE_result = t(RMSE_result)
kable(RMSE_result) %>% kable_styling("striped")

# Conclusion: Random forest turns out to be the best model which shows the best performance.
#             although it takes some time for computation, it is relatively shorter than the stepwise selection or the boosting method.
