# -----------------------------------------------------------------------------
# INTRO TO MACHINE LEARNING: REIV housing price prediction, data preparation
# -----------------------------------------------------------------------------


# Initialisation --------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(MASS)

setwd("c:/lab/real-estate-vic/analysis/")


# Import data -----------------------------------------------------------------
reiv_raw <-
  read.csv(
    "reiv.csv",
    header = TRUE,
    stringsAsFactors = FALSE
  ) %>%
    as_tibble()
# 
# reiv_raw <- read_csv("reiv.csv")


# Basic cleaning --------------------------------------------------------------
reiv <- reiv_raw
glimpse(reiv)
View(reiv)

# Drop Website field, since we'll assume this has no predictive power
reiv <- reiv %>% dplyr::select(-WebUrl)
reiv %>% glimpse()
reiv %>% print(n = 20)

# Remove records for multiple properties, i.e. where address includes "&"
reiv[grepl("&", reiv$AddressLine), ] %>% print(n = 10)
reiv <- reiv %>% filter(!grepl("&", reiv$AddressLine))

# Convert OutcomeDate string to date
class(reiv$OutcomeDate)
reiv <- reiv %>% mutate(OutcomeDate = as.Date(OutcomeDate))
class(reiv$OutcomeDate)

# Check for duplicates, and remove if exist
print(paste0(
  "Number of duplicates = ", nrow(reiv) - nrow(unique(reiv))
  ))
reiv <- unique(reiv)

reiv %>% glimpse()


# Filter for houses that have sold --------------------------------------------
unique(reiv$Classification)
unique(reiv$Outcome)

# Filter for only houses (or related, similar classifications)
# Ignoring flats, units, apartments, farms, etc.
nrow(reiv)
classifications_of_interest <- c(
  "house",
  "townhouse",
  "house - semi-detached",
  "residential warehouse",
  "house - duplex",
  "house - terrace",
  "house & granny flat",
  "house & flat"
)
houses <- reiv %>% filter(Classification %in% classifications_of_interest)
nrow(houses)

# Filter for only sold houses, either auction or private sales
# Ignoring passed in, sales via tender, or only at expression of interest stage
nrow(houses)
outcomes_of_interest <- c(
  "auction sale",
  "private sale",
  "sold before auction",
  "sold after auction"
)
houses_sold <- houses %>% filter(Outcome %in% outcomes_of_interest)
nrow(houses_sold)

# Confirm our filtering was successful
unique(houses_sold$Classification)
unique(houses_sold$Outcome)

# Let's have a look again ...
houses_sold %>% glimpse()
View(houses_sold)


# Explore price ---------------------------------------------------------------
# Some records where Price == NA, these are "undisclosed" prices
houses_sold %>% print(n = 20)
print(paste0(
  "Number of NAs in Price = ", sum(is.na(houses_sold$Price))
))

# Remove the "undisclosed"
houses_sold <- houses_sold %>% filter(!is.na(Price))
houses_sold %>% print(n = 20)
View(houses_sold)

# Plot histogram of Price
houses_sold %>% ggplot(aes(Price)) + geom_histogram(binwidth = 100e3)
# We'll come back this later


# Explore bedrooms ------------------------------------------------------------
# Is there a relationship between Price and NumberOfBedrooms?
houses_sold %>%
  ggplot(aes(NumberOfBedrooms, Price)) + 
    geom_point() + 
    geom_smooth(method = lm)

# There are records with NumberOfBedrooms = 0
ggplot(houses_sold, aes(NumberOfBedrooms)) + geom_bar()
sort(unique(houses_sold$NumberOfBedrooms))

# Remove the records with zero bedrooms--likely this is data that was not provided
houses_sold <- houses_sold %>% filter(NumberOfBedrooms != 0)

# Confirm that we removed those with zero bedrooms
houses_sold %>% 
  ggplot(aes(NumberOfBedrooms, Price)) + 
    geom_point() + 
    geom_smooth(method = lm)
sort(unique(houses_sold$NumberOfBedrooms))

houses_sold %>% glimpse()


# Outliers --------------------------------------------------------------------
# Remove outlier bedrooms and prices
houses_sold <- 
  houses_sold %>% 
  filter(NumberOfBedrooms <= 10) %>%
  filter(Price <= 7e6)

# Confirm outliers removed in our plots of NumberOfBedrooms and Price
houses_sold %>% ggplot(aes(NumberOfBedrooms)) + geom_bar()
houses_sold %>% ggplot(aes(Price)) + geom_histogram(binwidth = 100e3)
houses_sold %>% 
  ggplot(aes(NumberOfBedrooms, Price)) + 
    geom_point() + 
    geom_smooth(method = lm)

houses_sold %>% glimpse()


# Explore suburbs -------------------------------------------------------------
houses_sold %>% ggplot(aes(Suburb)) + geom_bar()

# Lots of suburbs!
print(paste0(
  "Number of suburbs = ", length(unique(houses_sold$Suburb))
))

# Create a summary table
suburb_summary <- 
  houses_sold %>% 
  group_by(Suburb) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(suburb_summary) <- c(
  "Suburb", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
suburb_summary %>% print(n = 20)

# There's lots of suburbs with only a few sales
suburbs_few_sales <- suburb_summary %>% filter(nSales <= 10) %>% pull(Suburb)
print(paste0(
  "Number of suburbs wtih <= 10 sales = ", length(suburbs_few_sales)
))

# Consolidate by treating those as "other" suburbs
# This will need to be re-implemented in Azure Machine Learning Studio
houses_suburb_other <- houses_sold
houses_suburb_other[houses_suburb_other$Suburb %in% suburbs_few_sales, 
                    "Suburb"] <- "other"
print(paste0(
  "Number of suburbs after consollidation = ", 
  length(unique(houses_suburb_other$Suburb))
))

# Re-summarise after consollidation
suburb_summary <- 
  houses_suburb_other %>% 
  group_by(Suburb) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(suburb_summary) <- c(
  "Suburb", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
suburb_summary %>% print(n = 20)
View(suburb_summary)

# Is there a relationship between Price and Suburb?
# Look at the price distribution for top 10 suburbs by sales
suburbs_ordered_by_nsales <- 
  suburb_summary[order(suburb_summary$nSales, decreasing = TRUE), ]
suburbs_top_10_nsales <- suburbs_ordered_by_nsales[1:10, ]
houses_suburb_other %>%
  filter(Suburb %in% suburbs_top_10_nsales$Suburb) %>%
  ggplot(aes(Suburb, Price)) +
    geom_boxplot()


# Explore date ----------------------------------------------------------------
glimpse(houses_sold)

# Explore sale year
houses_sold %>% ggplot(aes(factor(year(OutcomeDate)), Price)) + geom_boxplot()

# Convert date to number of days since first data collection: 2015-09-12
ref_date <- as.Date("2015-09-12")
houses_sold <- 
  houses_sold %>% 
  mutate(TimeDaysRelative = as.numeric(OutcomeDate - ref_date))

# Take a look at new feature: Time in days since the reference date
ordered_by_date <-
  houses_sold[order(houses_sold$OutcomeDate), ] %>%
  dplyr::select(
    Suburb, 
    AddressLine, 
    Classification, 
    Outcome, 
    OutcomeDate, 
    TimeDaysRelative
  )
ordered_by_date %>% head(10)
ordered_by_date %>% 
  filter(TimeDaysRelative == 0) %>% 
  print(n = 10)
ordered_by_date %>% tail(10)

# Is there a relationship between Price and Time?
houses_sold %>% 
  ggplot(aes(TimeDaysRelative, Price)) + 
    geom_point() + 
    geom_smooth(method = lm)


# Explore outcome -------------------------------------------------------------
houses_sold %>% ggplot(aes(Outcome)) + geom_bar()

# Create a summary table
outcome_summary <- 
  houses_sold %>% 
  group_by(Outcome) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(outcome_summary) <- c(
  "Outcome", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
  )
outcome_summary

# Is there a relationship between Price and Outcome?
# Look at the price distribution for the different outcomes
houses_sold %>% ggplot(aes(Outcome, Price)) + geom_boxplot()


# Explore classfication -------------------------------------------------------
houses_sold %>% ggplot(aes(Classification)) + geom_bar()

# Create a summary table
classification_summary <- 
  houses_sold %>% 
  group_by(Classification) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(classification_summary) <- c(
  "Classification", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
classification_summary

# There's a few classifications that don't have much data
# Consollidate duplex, semi-detached, terrace into townhouses
houses_classification_collated <- houses_sold
is_duplex_semi_terrace <- 
  houses_classification_collated$Classification %in% c(
    "house - duplex",
    "house - semi-detached",
    "house - terrace"
  )
houses_classification_collated[is_duplex_semi_terrace, 
                               "Classification"] <- "townhouse"

# Consollidate "house & flat" into "house"
houses_classification_collated[
  houses_classification_collated$Classification == "house & flat",
  "Classification"
] <- "house"

# Re-view after consollidation
houses_classification_collated %>% ggplot(aes(Classification)) + geom_bar()

# Re-summarise after consollidation
classification_summary <- 
  houses_classification_collated %>% 
  group_by(Classification) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(classification_summary) <- c(
  "Classification", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
classification_summary

# Is there a relationship between Price and Classification?
# Look at the price distribution for the different classifications
houses_classification_collated %>% 
  ggplot(aes(Classification, Price)) + 
    geom_boxplot()


# Explore agent ---------------------------------------------------------------
houses_sold %>% ggplot(aes(Agent)) + geom_bar()

# There are lots of agents!
print(paste0(
  "Number of agents = ", length(unique(houses_sold$Agent))
))

# Create summary table
agent_summary <- 
  houses_sold %>% 
  group_by(Agent) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(agent_summary) <- c(
  "Agent", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
agent_summary
View(agent_summary)

# A small-ish number of agents make up lots of sales
larger_agents <- agent_summary %>% filter(nSales >= 100) %>% pull(Agent)
print(paste0(
  "Number of agents with >= 100 sales = ", length(larger_agents)
))

# Consollidate by collecting all other agents together under "other"
houses_agent_other <- houses_sold
houses_agent_other[!(houses_agent_other$Agent %in% larger_agents), 
                   "Agent"] <- "other"
houses_agent_other %>% ggplot(aes(Agent)) + geom_bar()
print(paste0(
  "Number of agents after consollidation = ", 
  length(unique(houses_agent_other$Agent))
))

# Re-summarise after collation
agent_summary <- 
  houses_agent_other %>% 
  group_by(Agent) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(agent_summary) <- c(
  "Agent", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
agent_summary
View(agent_summary)

# Is there a relationship between Price and Agent?
# Look at the price distribution for top 6 agents by sales
agents_ordered_by_nsales <- 
  agent_summary[order(agent_summary$nSales, decreasing = TRUE), ]
agents_top_6_nsales <- agents_ordered_by_nsales[1:6, ]
houses_agent_other %>%
  filter(Agent %in% agents_top_6_nsales$Agent) %>%
  ggplot(aes(Agent, Price)) +
    geom_boxplot()


# Adding new features ---------------------------------------------------------

# Adding "/" and "-" detection
sum(grepl("/", houses_sold$AddressLine))
sum(grepl("-", houses_sold$AddressLine))
houses_sold <- houses_sold %>% mutate(Slash = grepl("/", AddressLine))
houses_sold <- houses_sold %>% mutate(Dash = (grepl("-", AddressLine) & !Slash))

houses_sold <- 
  houses_sold %>% 
  mutate(
    CharacterIndicator = ifelse(Slash, "Slash", ifelse(Dash, "Dash", "None"))
  )

houses_sold %>% 
  filter(Slash | Dash) %>%
  dplyr::select(Suburb, AddressLine, Classification, Slash, Dash) %>%
  print(n = 40)

# Summarise by "/" and "-" features
character_indicator_summary <- 
  houses_sold %>% 
  group_by(CharacterIndicator) %>% 
  summarize(
    n(), 
    min(Price), 
    median(Price), 
    max(Price), 
    mean(Price), 
    sd(Price))
colnames(character_indicator_summary) <- c(
  "Character", 
  "nSales", 
  "minPrice", 
  "medianPrice", 
  "maxPrice", 
  "meanPrice", 
  "sdPrice"
)
character_indicator_summary

# Is there a relationship between Price and these new "/" and "-" features?
houses_sold <- 
  houses_sold %>% 
  mutate(
    CharacterIndicator = ifelse(Slash, "Slash", ifelse(Dash, "Dash", "None"))
  )
houses_sold %>% ggplot(aes(CharacterIndicator, Price)) + geom_boxplot()


# Normalisation of Price ------------------------------------------------------
houses_sold %>% ggplot(aes(Price)) + geom_histogram(binwidth = 100e3)

# Price potentially log-normal
houses_sold <- houses_sold %>% mutate(lnPrice = log(Price))
houses_sold %>% ggplot(aes(lnPrice)) + geom_histogram(bins = 50)

# Get log-normal distribution parameters
distrib <- fitdistr(houses_sold$lnPrice, "normal")
distrib
lnPrice_mean <- distrib$estimate[["mean"]]
lnPrice_sd <- distrib$estimate[["sd"]]

# z-score normalisation
houses_sold <- 
  houses_sold %>% 
  mutate(zlnPrice = (lnPrice - lnPrice_mean) / lnPrice_sd)
houses_sold %>% 
  dplyr::select(Suburb, AddressLine, Price, lnPrice, zlnPrice) %>%
  print(n = 20)
houses_sold %>% ggplot(aes(zlnPrice)) + geom_histogram(bins = 50)


# Get ready for Azure Machine Learing Studio ----------------------------------
# Remove fields that don't want to port across, and ones that will need to be
# regenerated when scoring in production
houses_sold %>% glimpse()
houses_amls <-
  houses_sold %>%
  dplyr::select(-TimeDaysRelative, -Slash, -Dash, -CharacterIndicator, -lnPrice)
houses_amls %>% glimpse()
View(houses_amls)

# Wirte to CSV ready to be used in Azure Machine Learning Studio
houses_amls %>% write_csv("houses_ready_for_amls.csv")




# Denormalising from zlnPrice back to Price -----------------------------------
# To be implemented in Azure Machine Learning Studio
houses_alms <- houses_alms %>% mutate(ScoredPrice = exp(Scored.Label * lnPrice_sd + lnPrice_mean))
houses_alms %>% ggplot(aes(ScoredPrice, Price)) + geom_point() + geom_abline(intercept = 0, slope = 1)
