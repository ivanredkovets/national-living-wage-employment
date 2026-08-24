# UK National Living Wage and Employment
# 01_data_cleaning.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readxl)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)


# ------------------------------------------------------------
# 1. Employee jobs data
# ------------------------------------------------------------

jobs_raw <- read_excel(
  "data/raw/jobs02jun2026.xls",
  sheet = "EJ SA",
  col_names = FALSE
)


# Select the date column and SIC 2007 sections A-S
jobs_clean <- jobs_raw %>%
  slice(4:n()) %>%
  select(
    date = 1,
    agriculture = 3,
    mining = 4,
    manufacturing = 5,
    electricity_gas = 6,
    water_waste = 7,
    construction = 8,
    wholesale_retail = 9,
    transport_storage = 10,
    accommodation_food = 11,
    information_communication = 12,
    financial_insurance = 13,
    real_estate = 14,
    professional_scientific = 15,
    administrative_support = 16,
    public_admin = 17,
    education = 18,
    health_social_work = 19,
    arts_entertainment = 20,
    other_services = 21
  ) %>%
  mutate(
    date = str_trim(date),
    date_clean = str_extract(date, "[A-Za-z]{3} [0-9]{2}"),
    quarter_date = as.Date(
      parse_date_time(date_clean, orders = "b y")
    )
  ) %>%
  filter(
    !is.na(quarter_date),
    quarter_date >= ymd("2012-01-01"),
    quarter_date <= ymd("2019-12-31")
  )


# Convert from wide to long panel format
jobs_long <- jobs_clean %>%
  select(-date, -date_clean) %>%
  pivot_longer(
    cols = -quarter_date,
    names_to = "industry",
    values_to = "employee_jobs"
  ) %>%
  mutate(
    employee_jobs = as.numeric(employee_jobs)
  ) %>%
  arrange(quarter_date, industry)


# ------------------------------------------------------------
# 2. NLW exposure data
# ------------------------------------------------------------

exposure_raw <- read_csv(
  "data/raw/NLW-industry-data-download.csv",
  show_col_types = FALSE
)


exposure_clean <- exposure_raw %>%
  select(
    industry_raw = Industry,
    exposure = 3
  ) %>%
  mutate(
    industry = case_when(
      industry_raw == "AGRICULTURE, FORESTRY AND FISHING" ~ "agriculture",
      industry_raw == "MINING AND QUARRYING" ~ "mining",
      industry_raw == "MANUFACTURING" ~ "manufacturing",
      industry_raw == "ELECTRICITY, GAS, STEAM AND AIR CONDITIONING SUPPLY" ~ "electricity_gas",
      industry_raw == "WATER SUPPLY; SEWERAGE, WASTE MANAGEMENT AND REMEDIATION ACTIVITIES" ~ "water_waste",
      industry_raw == "CONSTRUCTION" ~ "construction",
      industry_raw == "WHOLESALE AND RETAIL TRADE; REPAIR OF MOTOR VEHICLES AND MOTORCYCLES" ~ "wholesale_retail",
      industry_raw == "TRANSPORTATION AND STORAGE" ~ "transport_storage",
      industry_raw == "ACCOMMODATION AND FOOD SERVICE ACTIVITIES" ~ "accommodation_food",
      industry_raw == "INFORMATION AND COMMUNICATION" ~ "information_communication",
      industry_raw == "FINANCIAL AND INSURANCE ACTIVITIES" ~ "financial_insurance",
      industry_raw == "REAL ESTATE ACTIVITIES" ~ "real_estate",
      industry_raw == "PROFESSIONAL, SCIENTIFIC AND TECHNICAL ACTIVITIES" ~ "professional_scientific",
      industry_raw == "ADMINISTRATIVE AND SUPPORT SERVICE ACTIVITIES" ~ "administrative_support",
      industry_raw == "PUBLIC ADMINISTRATION AND DEFENCE; COMPULSORY SOCIAL SECURITY" ~ "public_admin",
      industry_raw == "EDUCATION" ~ "education",
      industry_raw == "HUMAN HEALTH AND SOCIAL WORK ACTIVITIES" ~ "health_social_work",
      industry_raw == "ARTS, ENTERTAINMENT AND RECREATION" ~ "arts_entertainment",
      industry_raw == "OTHER SERVICE ACTIVITIES" ~ "other_services",
      TRUE ~ NA_character_
    )
  ) %>%
  select(industry, exposure)


# Confirm that industry classifications match
stopifnot(
  length(setdiff(jobs_long$industry, exposure_clean$industry)) == 0,
  length(setdiff(exposure_clean$industry, jobs_long$industry)) == 0
)


# ------------------------------------------------------------
# 3. Merge employment and exposure
# ------------------------------------------------------------

panel <- jobs_long %>%
  left_join(
    exposure_clean,
    by = "industry"
  )


# ------------------------------------------------------------
# 4. Analysis variables
# ------------------------------------------------------------

panel <- panel %>%
  mutate(
    post = if_else(
      quarter_date >= ymd("2016-06-01"),
      1,
      0
    ),
    log_jobs = log(employee_jobs),
    event_time = (year(quarter_date) - 2016) * 4 +
      (quarter(quarter_date) - 2)
  )


# ------------------------------------------------------------
# 5. Final checks
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 608,
  n_distinct(panel$industry) == 19,
  n_distinct(panel$quarter_date) == 32,
  sum(is.na(panel)) == 0,
  min(panel$exposure) == 0.3,
  max(panel$exposure) == 33.2
)

quarter_check <- panel %>%
  count(industry)

stopifnot(
  min(quarter_check$n) == 32,
  max(quarter_check$n) == 32
)


# ------------------------------------------------------------
# 6. Save processed data
# ------------------------------------------------------------

write_csv(
  panel,
  "data/processed/nlw_employment_panel.csv"
)

saveRDS(
  panel,
  "data/processed/nlw_employment_panel.rds"
)

