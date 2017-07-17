
library(ggplot2)
library(tibble)
library(tidyr)
library(readr)
library(purr)
library(dplyr)


setwd("c:/lab/real-estate-vic")
reiv.raw <- read.csv("all_records.csv", header = TRUE, stringsAsFactors = FALSE)

# Explore data
glimpse(reiv.raw)
head(reiv.raw, 20)

# Drop Agent and Website -- Assume these have no predictive power
reiv <- reiv.raw %>% dplyr::select(-Agent, -Website)
head(reiv, 20)

# Unwanted data
unique(reiv$Type)
unique(reiv$Outcome)

# Filter for only houses that have been sold, and remove duplicate rows
houses <- reiv %>% filter(Type %in% c("house", "house - semi-detached", "house - duplex", "townhouse", "house - terrace"))
houses <- houses %>% filter(Outcome %in% c("private sale", "auction sale", "sold before auction", "sold after auction", "sale by tender"))
houses <- unique(houses)
glimpse(houses)
head(houses, 100)

# Explore price
ggplot(houses, aes(Price)) + geom_histogram(binwidth = 100000)

# Remove undisclosed prices
houses <- houses %>% filter(Price != 0)
glimpse(houses)
head(houses, 100)
ggplot(houses, aes(Price)) + geom_histogram(binwidth = 100000)

# Explore bedrooms
ggplot(houses, aes(NumberOfBedrooms)) + geom_bar()

# Remove entries with zero bedrooms
houses <- houses %>% filter(NumberOfBedrooms != 0)
glimpse(houses)
ggplot(houses, aes(NumberOfBedrooms)) + geom_bar()

# Explore bedrooms
lin.mod.bedrooms <- lm(Price ~ NumberOfBedrooms, houses)
summary(lin.mod.bedrooms)
ggplot(houses, aes(NumberOfBedrooms, Price)) + geom_point() + geom_smooth(method = lm)

# Remove outlier bedrooms and prices
houses <- houses %>% filter(NumberOfBedrooms <= 15) %>% filter(Price <= 9e6)
lin.mod.bedrooms <- lm(Price ~ NumberOfBedrooms, houses)
summary(lin.mod.bedrooms)
ggplot(houses, aes(NumberOfBedrooms, Price)) + geom_point() + geom_smooth(method = lm)

# Explore suburbs
suburbs <- houses %>% group_by(Suburb) %>% summarize(n(), min(Price), median(Price), max(Price), mean(Price), sd(Price))
colnames(suburbs) <- c("Suburb", "nSales", "minPrice", "medianPrice", "maxPrice", "meanPrice", "sdPrice")
suburbs
ggplot(houses, aes(Suburb)) + geom_bar()

# Explore suburbs for predictive power
suburbs.ordered <- suburbs[order(suburbs$nSales, decreasing = TRUE), ]
suburbs.top.10 <- suburbs.ordered[1:10, ]
ggplot(filter(houses, Suburb %in% suburbs.top.10$Suburb), aes(Suburb, Price)) + geom_boxplot()

# Remove suburbs with too few sales
suburbs.few.sales <- suburbs %>% filter(nSales <= 3)
suburbs.few.sales
unique(suburbs.few.sales$Suburb)
houses <- houses %>% filter(!(Suburb %in% suburbs.few.sales$Suburb))
glimpse(houses)

# Explore type
types <- houses %>% group_by(Type) %>% summarize(n(), min(Price), median(Price), max(Price), mean(Price), sd(Price))
colnames(types) <- c("Type", "nSales", "minPrice", "medianPrice", "maxPrice", "meanPrice", "sdPrice")
types # In machine learning, group non houses or townhouses into "house-other"!!!
ggplot(houses, aes(Type, Price)) + geom_boxplot()

# Explore sale year
ggplot(houses, aes(factor(Year), Price)) + geom_boxplot()

# Convert Year, Month, Day to DateSold and DaysRel field
houses <- houses %>% mutate(DateSold = as.Date(paste0(Year, "-", Month, "-", Day)))
houses <- houses %>% mutate(DaysRel = as.numeric(DateSold - Sys.Date()))
head(houses, 10)
tail(houses, 10)

# Linear model of Price as function of DaysRel
lin.mod.time <- lm(Price ~ DaysRel, houses)
summary(lin.mod.time)
ggplot(houses, aes(DaysRel, Price)) + geom_point() + geom_smooth(method = lm)

# Remove outlier sale date
houses <- houses %>% filter(DaysRel > -800)
lin.mod.time <- lm(Price ~ DaysRel, houses)
summary(lin.mod.time)
ggplot(houses, aes(DaysRel, Price)) + geom_point() + geom_smooth(method = lm)

# Feature engineering: Adding "/", "&" and "-" detection
houses <- houses %>% mutate(Slash = grepl("/", Address))
houses <- houses %>% mutate(Ampersand = grepl("&", Address))
houses <- houses %>% mutate(Dash = grepl("-", Address))
head(filter(houses, Slash | Ampersand | Dash), 40)

# Explore new features for predictive power
houses <- houses %>% mutate(CharInd = ifelse(Ampersand, "Ampersand", ifelse(Slash, "Slash", ifelse(Dash, "Dash", "None"))))
char.ind <- houses %>% group_by(CharInd) %>% summarize(n(), min(Price), median(Price), max(Price), mean(Price), sd(Price))
colnames(char.ind) <- c("CharInd", "nSales", "minPrice", "medianPrice", "maxPrice", "meanPrice", "sdPrice")
char.ind
ggplot(houses, aes(CharInd, Price)) + geom_boxplot()

# Exclude Ampersands -- Tend to indicate multiple houses sold at once
houses <- houses %>% filter(!Ampersand)

# Explore Price
ggplot(houses, aes(Price)) + geom_histogram(binwidth = 100000)

# Price potentially log-normal
houses <- houses %>% mutate(lnPrice = log(Price))
ggplot(houses, aes(lnPrice)) + geom_histogram(bins = 50)
library(MASS)
distrib <- fitdistr(houses$lnPrice, "normal")
distrib
lnPrice.mean <- distrib$estimate[["mean"]]
lnPrice.sd <- distrib$estimate[["sd"]]

# z-score normalisation
houses <- houses %>% mutate(zlnPrice = (lnPrice - lnPrice.mean) / lnPrice.sd)
head(houses, 20)
ggplot(houses, aes(zlnPrice)) + geom_density()

# Consider removing fields that won't be supplied by user app!!!

## Ready for machine learning
glimpse(houses)
## Machine learing time!

# Code for denormalising
houses <- houses %>% mutate(ScoredPrice = exp(Scored.Label * lnPrice.sd + lnPrice.mean))
ggplot(houses, aes(ScoredPrice, Price)) + geom_point() + geom_abline(intercept = 0, slope = 1)