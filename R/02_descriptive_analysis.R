# UK National Living Wage and Employment
# 02_descriptive_analysis.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(ggplot2)


# ------------------------------------------------------------
# 1. Load processed data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/nlw_employment_panel.csv",
  show_col_types = FALSE
)


glimpse(panel)

panel %>%
  summarise(
    observations = n(),
    industries = n_distinct(industry),
    quarters = n_distinct(quarter_date),
    min_exposure = min(exposure),
    max_exposure = max(exposure)
  )

# ------------------------------------------------------------
# 2. NLW exposure by industry
# ------------------------------------------------------------

exposure_by_industry <- panel %>%
  distinct(industry, exposure) %>%
  arrange(desc(exposure))

print(exposure_by_industry)

exposure_plot <- ggplot(
  exposure_by_industry,
  aes(
    x = reorder(industry, exposure),
    y = exposure
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Pre-NLW Exposure by Industry",
    subtitle = "Share of employees aged 25+ paid below the future National Living Wage",
    x = NULL,
    y = "Exposure (%)"
  ) +
  theme_minimal()
ggsave(
  "figures/exposure_by_industry.png",
  exposure_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 3. Employment trends by industry
# ------------------------------------------------------------

raw_employment_plot <- ggplot(
  panel,
  aes(
    x = quarter_date,
    y = employee_jobs,
    group = industry
  )
) +
  geom_line() +
  labs(
    title = "Employee Jobs by Industry",
    subtitle = "Seasonally adjusted employee jobs, 2012Q1–2019Q4",
    x = NULL,
    y = "Employee jobs (thousands)"
  ) +
  theme_minimal()
ggsave(
  "figures/raw_employment_trends.png",
  raw_employment_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 4. Indexed employment trends
# ------------------------------------------------------------

panel_indexed <- panel %>%
  group_by(industry) %>%
  arrange(quarter_date, .by_group = TRUE) %>%
  mutate(
    employment_index = employee_jobs / first(employee_jobs) * 100
  ) %>%
  ungroup()

indexed_employment_plot <- ggplot(
  panel_indexed,
  aes(
    x = quarter_date,
    y = employment_index,
    group = industry
  )
) +
  geom_line() +
  geom_hline(
    yintercept = 100,
    linetype = "dashed"
  ) +
  geom_vline(
    xintercept = as.Date("2016-06-01"),
    linetype = "dashed"
  ) +
  labs(
    title = "Indexed Employment by Industry",
    subtitle = "Seasonally adjusted employee jobs, 2012Q1 = 100",
    x = NULL,
    y = "Employment index (2012Q1 = 100)"
  ) +
  theme_minimal()
ggsave(
  "figures/indexed_employment_trends.png",
  indexed_employment_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 5. Higher vs lower exposure trends
# ------------------------------------------------------------

median_exposure <- median(panel_indexed$exposure)

median_exposure


panel_groups <- panel_indexed %>%
  mutate(
    exposure_group = if_else(
      exposure >= median_exposure,
      "Higher exposure",
      "Lower exposure"
    )
  )

panel_groups %>%
  distinct(industry, exposure, exposure_group) %>%
  arrange(desc(exposure))

group_trends <- panel_groups %>%
  group_by(quarter_date, exposure_group) %>%
  summarise(
    mean_employment_index = mean(employment_index),
    .groups = "drop"
  )

exposure_group_plot <- ggplot(
  group_trends,
  aes(
    x = quarter_date,
    y = mean_employment_index,
    color = exposure_group
  )
) +
  geom_line(linewidth = 1) +
  geom_hline(
    yintercept = 100,
    linetype = "dashed"
  ) +
  geom_vline(
    xintercept = as.Date("2016-06-01"),
    linetype = "dashed"
  ) +
  labs(
    title = "Employment Trends by NLW Exposure",
    subtitle = "Industries grouped by median pre-NLW exposure; 2012Q1 = 100",
    x = NULL,
    y = "Mean employment index (2012Q1 = 100)",
    color = "Exposure group"
  ) +
  theme_minimal()
ggsave(
  "figures/exposure_group_trends.png",
  exposure_group_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 6. Pre-NLW employment trends and exposure
# ------------------------------------------------------------

pre_trends <- panel %>%
  filter(quarter_date < as.Date("2016-06-01")) %>%
  group_by(industry) %>%
  arrange(quarter_date, .by_group = TRUE) %>%
  summarise(
    exposure = first(exposure),
    first_jobs = first(employee_jobs),
    last_jobs = last(employee_jobs),
    pre_growth = (last_jobs / first_jobs - 1) * 100,
    .groups = "drop"
  )

pre_trends %>%
  arrange(desc(exposure))

pretrend_plot <- ggplot(
  pre_trends,
  aes(
    x = exposure,
    y = pre_growth
  )
) +
  geom_point(size = 2.5) +
  geom_smooth(
    method = "lm",
    se = FALSE
  ) +
  labs(
    title = "Pre-NLW Employment Growth and Exposure",
    subtitle = "Employment growth from 2012Q1 to 2016Q1 across industries",
    x = "Pre-NLW exposure (%)",
    y = "Employment growth (%)"
  ) +
  theme_minimal()
ggsave(
  "figures/pre_nlw_trends_exposure.png",
  pretrend_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 7. Outliers and influential industries
# ------------------------------------------------------------

exposure_summary <- exposure_by_industry %>%
  summarise(
    mean_exposure = mean(exposure),
    median_exposure = median(exposure),
    sd_exposure = sd(exposure),
    max_exposure = max(exposure),
    second_highest = sort(exposure, decreasing = TRUE)[2]
  )

print(exposure_summary)

pre_trends_no_accom <- pre_trends %>%
  filter(industry != "accommodation_food")

pretrend_model_full <- lm(
  pre_growth ~ exposure,
  data = pre_trends
)

pretrend_model_no_accom <- lm(
  pre_growth ~ exposure,
  data = pre_trends_no_accom
)

coef(pretrend_model_full)
coef(pretrend_model_no_accom)