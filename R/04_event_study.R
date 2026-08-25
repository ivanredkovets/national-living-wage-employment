# UK National Living Wage and Employment
# 04_event_study.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(fixest)
library(ggplot2)


# ------------------------------------------------------------
# 1. Load processed data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/nlw_employment_panel.csv",
  show_col_types = FALSE
)

glimpse(panel)


# ------------------------------------------------------------
# 2. Prepare and check event-study data
# ------------------------------------------------------------

panel_event <- panel %>%
  mutate(
    exposure_10pp = exposure / 10
  )

panel_event %>%
  distinct(quarter_date, event_time) %>%
  arrange(quarter_date)

panel_event %>%
  distinct(quarter_date, event_time) %>%
  filter(event_time >= -3, event_time <= 3) %>%
  arrange(quarter_date)

# ------------------------------------------------------------
# 3. Event-study regression
# ------------------------------------------------------------

event_model <- feols(
  log_jobs ~ i(
    event_time,
    exposure_10pp,
    ref = -1
  ) | industry + quarter_date,
  data = panel_event,
  cluster = ~industry
)

summary(event_model)

# ------------------------------------------------------------
# 4. Event-study plot
# ------------------------------------------------------------

iplot(
  event_model,
  ref.line = 0,
  xlab = "Quarters relative to NLW introduction",
  ylab = "Effect of 10 pp higher NLW exposure on log employment",
  main = "Event Study: NLW Exposure and Employment"
)

png(
  "figures/event_study.png",
  width = 2400,
  height = 1800,
  res = 300
)

iplot(
  event_model,
  ref.line = 0,
  xlab = "Quarters relative to NLW introduction",
  ylab = "Effect of 10 pp higher NLW exposure on log employment",
  main = "Event Study: NLW Exposure and Employment"
)

dev.off()

# ------------------------------------------------------------
# 5. Joint test of pre-treatment coefficients
# ------------------------------------------------------------

wald(
  event_model,
  keep = "event_time::-(17|16|15|14|13|12|11|10|9|8|7|6|5|4|3|2):"
)