# UK National Living Wage and Employment
# 06_results.R


# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(fixest)
library(ggplot2)


# ------------------------------------------------------------
# 1. Run analysis scripts
# ------------------------------------------------------------

source("R/03_main_models.R")
source("R/04_event_study.R")
source("R/05_robustness.R")

#-------------------------------------------------------------
# 2.Main results model
#-------------------------------------------------------------

models <- list(
  "Baseline" = main_model, 
  "Short model" = short_window_model,
  "Excl. Accom. & Food" = no_accom_model,
  "Industry trends" = trends_model,
  "Employment weighted" = weighted_model, 
  "No anticipation" = anticipation_model
  
)

extract_results <- function(model,name){
  coef_table <- coeftable(model)
  ci <- confint(model)
  
  tibble(
    specification = name,
    estimate = coef_table["exposure_10pp:post", "Estimate"],
    std_error = coef_table["exposure_10pp:post", "Std. Error"],
    t_value = coef_table["exposure_10pp:post", "t value"],
    p_value = coef_table["exposure_10pp:post", "Pr(>|t|)"],
    conf_low = ci["exposure_10pp:post", 1],
    conf_high = ci["exposure_10pp:post", 2],
    observations = nobs(model)
  )
}

main_results <- bind_rows(
  lapply(
    names(models),
    function(name) extract_results(models[[name]], name)
  )
)

main_results

write_csv(
  main_results,
  "tables/main_results.csv"
)

# ------------------------------------------------------------
# 3. Bootstrap inference summary
# ------------------------------------------------------------

bootstrap_results <- tibble(
  specification = "Baseline: wild cluster bootstrap",
  estimate = bootstrap_main$point_estimate,
  statistic = bootstrap_main$t_stat,
  p_value = bootstrap_main$p_val,
  conf_low = bootstrap_main$conf_int[1],
  conf_high = bootstrap_main$conf_int[2],
  observations = bootstrap_main$N,
  clusters = bootstrap_main$N_G
)

print(bootstrap_results)

write_csv(
  bootstrap_results,
  "tables/bootstrap_results.csv"
)

# ------------------------------------------------------------
# 4. Event-study output
# ------------------------------------------------------------

event_results <- coeftable(event_model)

event_ci <- confint(event_model)

event_study_results <- tibble(
  term = rownames(event_results),
  estimate = event_results[, "Estimate"],
  std_error = event_results[, "Std. Error"],
  t_value = event_results[, "t value"],
  p_value = event_results[, "Pr(>|t|)"],
  conf_low = event_ci[, 1],
  conf_high = event_ci[, 2]
)

event_study_results

event_study_results <- event_study_results %>%
  mutate(
    event_time = as.integer(
      sub("event_time::(-?[0-9]+):exposure_10pp", "\\1", term)
    )
  ) %>%
  select(
    event_time,
    estimate,
    std_error,
    t_value,
    p_value,
    conf_low,
    conf_high
  )

event_study_results

write_csv(
  event_study_results,
  "tables/event_study_results.csv"
)

# ------------------------------------------------------------
# 5. Robustness coefficient plot
# ------------------------------------------------------------

robustness_plot <- ggplot(
  main_results,
  aes(
    x = estimate,
    y = reorder(specification, estimate)
  )
) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +
  geom_errorbar(
    aes(
      xmin = conf_low,
      xmax = conf_high
    ),
    width = 0.15,
    orientation = "y"
  ) +
  geom_point(size = 2.5) +
  labs(
    title = "Robustness of NLW Employment Estimates",
    subtitle = "Effect associated with 10 percentage points higher pre-NLW exposure",
    x = "Estimate with 95% confidence interval",
    y = NULL
  ) +
  theme_minimal()

robustness_plot

ggsave(
  "figures/robustness_coefficients.png",
  robustness_plot,
  width = 8,
  height = 5,
  dpi = 300
)