
library(ggplot2)
library(tibble)
library(tidyr)
library(readr)
library(purr)
library(dplyr)


setwd("c:/lab/real-estate-vic")
reiv.raw <- read.csv("all_records.csv", header = TRUE, stringsAsFactors = FALSE)

# Explore data
head(reiv.raw, 200)

# Drop Agent and Website -- Assume these have no predictive power
reiv <- reiv.raw %>% dplyr::select(-Agent, -Website)
head(reiv, 20)

# Filter out only houses that have been sold
houses <- reiv %>% filter(Type %in% c("house", "house - semi-detached", "house - duplex"))
houses <- houses %>% filter(Outcome %in% c("private sale", "auction sale", "sold before auction", "sold after auction", "sale by tender"))
head(houses, 100)

# Remove duplicate rows and undisclosed prices
houses <- unique(houses)

# Explore price
ggplot(houses, aes(Price)) + geom_histogram(binwidth = 100000)

# Remove undisclosed prices
houses <- houses %>% filter(Price != 0)
head(houses, 100)

# Explore bedrooms
ggplot(houses, aes(NumberOfBedrooms)) + geom_bar()

# Remove entries with zero bedrooms
houses <- houses %>% filter(NumberOfBedrooms != 0)
ggplot(houses, aes(NumberOfBedrooms)) + geom_bar()

# Explore bedrooms
lin.mod.bedrooms <- lm(Price ~ NumberOfBedrooms, houses)
summary(lin.mod.bedrooms)
ggplot(houses, aes(NumberOfBedrooms, Price)) + geom_point() + geom_smooth(method = lm)

# Explore suburbs
suburbs <- houses %>% group_by(Suburb) %>% summarize(n(), min(Price), median(Price), max(Price), mean(Price), sd(Price))
n.suburbs <- nrow(suburbs)
n.suburbs
head(suburbs, 50) # Doesn't work on tibble!!!
ggplot(houses, aes(Suburb)) + geom_bar()

# Explore suburbs continued
suburbs.top.10 <- suburbs[, 1:10]

# Explore sale year
ggplot(houses, aes(factor(Year), Price)) + geom_boxplot()

# Convert Year, Month, Day to DateSold and DaysRel field
houses <- houses %>% mutate(DateSold = as.Date(paste0(Year, "-", Month, "-", Day)))
houses <- houses %>% mutate(DaysRel = as.numeric(DateSold - Sys.Date()))
head(houses, 50)

# Linear model of Price as function of DaysRel
lin.mod.time <- lm(Price ~ DaysRel, houses)
summary(lin.mod.time)
ggplot(houses, aes(DaysRel, Price)) + geom_point() + geom_smooth(method = lm)

# Feature engineering: Adding "/", "&" and "-" detection
houses <- houses %>% mutate(Slash = grepl("/", Address))
houses <- houses %>% mutate(Ampersand = grepl("&", Address))
houses <- houses %>% mutate(Dash = grepl("-", Address))
head(filter(houses, Slash | Ampersand | Dash), 50)

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
head(houses, 50)
ggplot(houses, aes(zlnPrice)) + geom_density()

## Machine learing time!

# Code for denormalising
houses <- houses %>% mutate(ScoredPrice = exp(Scored.Label * lnPrice.sd + lnPrice.mean))
ggplot(houses, aes(ScoredPrice, Price)) + geom_point() + geom_abline(intercept = 0, slope = 1)