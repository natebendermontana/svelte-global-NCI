library(jsonlite)
library(dplyr)
library(here)

# Load the JSON files
data_ids <- fromJSON(here("src/data", "data.json"))  # Contains country names and IDs
scores <- fromJSON(here("src/data", "nci_scores.json"))  # Contains country names and scores

# Convert both to data frames for easier merging
data_df <- as.data.frame(data_ids) %>%
  select(country, id) %>%
  rename(Country = country, ID = id)

scores_df <- as.data.frame(scores)

# fix some naming variations
scores_name_corrections <- c(
  "Bosnia and Herz." = "Bosnia and Herzegovina",
  "Brunei" = "Brunei Darussalam",
  "Central Af. Rep." = "Central African Republic",
  "Ivory Coast" = "Côte d'Ivoire",
  "DR Congo" = "Congo, Democratic Republic of the",
  "Cape Verde" = "Cabo Verde",
  "Czech Republic" = "Czechia",
  "Micronesia" = "Micronesia (Federated States of)",
  "South Korea" = "Korea, Republic of",
  "Laos" = "Lao People's Democratic Republic",
  "Moldova" = "Moldova, Republic of",
  "Venezuela" = "Venezuela (Bolivarian Republic of)",
  "East Timor" = "Timor-Leste",
  "Tanzania" = "Tanzania, United Republic of",
  "St. Vincent and the Grenadines" = "Saint Vincent and the Grenadines",
  "Korea (Democratic People's Republic of)" = "North Korea" 
  )

data_name_corrections <- c(
  "Korea (Democratic People's Republic of)" = "North Korea" 
)

scores_df$Country <- recode(scores_df$Country, !!!scores_name_corrections)
data_df$Country <- recode(data_df$Country, !!!data_name_corrections)

# add three countries that have scores but not IDs
missing_entries <- data.frame(
  Country = c("Taiwan", "Slovakia", "Eritrea"),
  ID = c("158", "703", "232"),
  stringsAsFactors = FALSE
)
data_df <- bind_rows(data_df, missing_entries)

# Merge datasets
merged_df <- left_join(data_df, scores_df, by = "Country")

# Identify any remaining unmatched countries
missing_countries <- merged_df %>% filter(is.na(Score)) %>% select(Country)

# merged_df <- merged_df %>%
#   mutate(Score = ifelse(is.na(Score), "No score", Score))
colnames(merged_df) <- tolower(colnames(merged_df))
merged_df <- merged_df %>%
  mutate(score = ifelse(is.na(score), "No score", score))

#####################
# Save merged data and missing countries
write_json(merged_df, here("src/data", "nci_final_data.json"), pretty = TRUE)

