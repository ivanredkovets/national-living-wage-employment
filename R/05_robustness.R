# UK National Living Wage and Employment
# 05_robustness.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(fixest)
library(fwildclusterboot)


# ------------------------------------------------------------
# 1. Load processed data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/nlw_employment_panel.csv",
  show_col_types = FALSE
)

panel_model <- panel %>%
  mutate(
    exposure_10pp = exposure / 10
  )

glimpse(panel_model)


# ------------------------------------------------------------
# 2. Baseline model
# ------------------------------------------------------------

baseline_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_model,
  cluster = ~industry
)

summary(baseline_model)

# ------------------------------------------------------------
# 3. Robustness: shorter sample window
# ------------------------------------------------------------

panel_short <- panel_model %>%
  filter(
    quarter_date >= as.Date("2014-03-01"),
    quarter_date <= as.Date("2018-12-01")
  )

panel_short %>%
  summarise(
    observations = n(),
    industries = n_distinct(industry),
    quarters = n_distinct(quarter_date),
    first_quarter = min(quarter_date),
    last_quarter = max(quarter_date)
  )

short_window_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_short,
  cluster = ~industry
)

summary(short_window_model)

confint(short_window_model)

# ------------------------------------------------------------
# 4. Robustness: exclude Accommodation & Food
# ------------------------------------------------------------

panel_no_accom <- panel_model %>%
  filter(industry != "accommodation_food")

panel_no_accom %>%
  summarise(
    observations = n(),
    industries = n_distinct(industry),
    quarters = n_distinct(quarter_date),
    max_exposure = max(exposure)
  )

no_accom_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_no_accom,
  cluster = ~industry
)

summary(no_accom_model)

confint(no_accom_model)

# ------------------------------------------------------------
# 5. Robustness: industry-specific linear trends
# ------------------------------------------------------------

panel_trends <- panel_model %>%
  arrange(quarter_date, industry) %>%
  mutate(
    time_trend = as.integer(factor(
      quarter_date,
      levels = sort(unique(quarter_date))
    ))
  )

panel_trends %>%
  distinct(quarter_date, time_trend) %>%
  arrange(quarter_date)

trends_model <- feols(
  log_jobs ~ exposure_10pp:post + i(industry, time_trend) |
    industry + quarter_date,
  data = panel_trends,
  cluster = ~industry
)

summary(trends_model)

# ------------------------------------------------------------
# 6. Robustness: employment-weighted specification
# ------------------------------------------------------------

industry_weights <- panel_model %>%
  filter(quarter_date == as.Date("2016-03-01")) %>%
  select(
    industry,
    employment_weight = employee_jobs
  )

industry_weights %>%
  arrange(desc(employment_weight))

panel_weighted <- panel_model %>%
  left_join(
    industry_weights,
    by = "industry"
  )

panel_weighted %>%
  distinct(industry, employment_weight) %>%
  arrange(desc(employment_weight))

weighted_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_weighted,
  weights = ~employment_weight,
  cluster = ~industry
)

summary(weighted_model)

# ------------------------------------------------------------
# 7. Robustness: small-cluster inference
# ------------------------------------------------------------

panel_bootstrap <- panel_model %>%
  mutate(
    industry = factor(industry),
    quarter_date = factor(quarter_date)
  )

bootstrap_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_bootstrap,
  cluster = ~industry
)

summary(bootstrap_model)

set.seed(12345)
dqrng::dqset.seed(12345)

bootstrap_main <- boottest(
  bootstrap_model,
  param = "exposure_10pp:post",
  clustid = "industry",
  B = 9999,
  engine = "R"
)

summary(bootstrap_main)

# ------------------------------------------------------------
# 8. Robustness: exclude potential anticipation period
# ------------------------------------------------------------

panel_no_anticipation <- panel_model %>%
  filter(!(quarter_date >= as.Date("2015-06-01") & quarter_date < as.Date("2016-06-01")))

anticipation_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_no_anticipation,
  cluster = ~industry
)

summary(anticipation_model)