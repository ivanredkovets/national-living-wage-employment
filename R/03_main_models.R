# UK National Living Wage and Employment
# 03_main_models.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(fixest)


# ------------------------------------------------------------
# 1. Load processed data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/nlw_employment_panel.csv",
  show_col_types = FALSE
)

glimpse(panel)

# ------------------------------------------------------------
# 2. Construct regression variables
# ------------------------------------------------------------

panel_model <- panel %>%
  mutate(
    post = if_else(
      quarter_date >= as.Date("2016-06-01"),
      1,
      0
    ),
    log_jobs = log(employee_jobs),
    exposure_10pp = exposure / 10
  )

panel_model %>%
  summarise(
    observations = n(),
    industries = n_distinct(industry),
    quarters = n_distinct(quarter_date),
    missing_jobs = sum(is.na(employee_jobs)),
    missing_log_jobs = sum(is.na(log_jobs)),
    missing_exposure = sum(is.na(exposure_10pp))
  )

panel_model %>%
  group_by(post) %>%
  summarise(
    first_quarter = min(quarter_date),
    last_quarter = max(quarter_date),
    observations = n(),
    .groups = "drop"
  )

# ------------------------------------------------------------
# 3. Main continuous-exposure DiD
# ------------------------------------------------------------

main_model <- feols(
  log_jobs ~ exposure_10pp:post | industry + quarter_date,
  data = panel_model,
  cluster = ~industry
)

summary(main_model)

# ------------------------------------------------------------
# 4. Main estimate and confidence interval
# ------------------------------------------------------------

confint(main_model)

# ------------------------------------------------------------
# 5. Regression table
# ------------------------------------------------------------

etable(
  main_model,
  dict = c(
    "exposure_10pp:post" = "Exposure × Post (10 pp)"
  ),
  fitstat = ~n + r2 + wr2
)