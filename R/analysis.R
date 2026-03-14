# analysis.R — Regression and t-test functions

library(broom)
library(knitr)
library(dplyr)

run_regressions <- function(df) {
  list(
    assisted   = lm(scores_assisted   ~ GPT_base + GPT_tutor + prev_gpa, data = df),
    unassisted = lm(scores_unassisted ~ GPT_base + GPT_tutor + prev_gpa, data = df)
  )
}

format_regression_table <- function(model, title) {
  tidy_model <- tidy(model, conf.int = TRUE) %>%
    mutate(across(where(is.numeric), \(x) round(x, digits = 3))) %>%
    mutate(p.value = ifelse(p.value < 0.001, "< 0.001", format(p.value, digits = 3)))

  kable(
    tidy_model,
    col.names = c("Predictor", "Estimate", "Std. Error", "t value",
                  "p-value", "CI Lower", "CI Upper"),
    caption = title,
    align = c("l", rep("r", 6))
  )
}

perform_ttest <- function(group1, group2, test_name) {
  result <- t.test(group1, group2)
  data.frame(
    Test       = test_name,
    t_statistic = round(result$statistic, 3),
    df         = round(result$parameter, 2),
    p_value    = ifelse(result$p.value < 0.001,
                        "< 0.001", format(result$p.value, digits = 3)),
    mean_diff  = round(result$estimate[1] - result$estimate[2], 3)
  )
}

run_all_ttests <- function(df) {
  ctrl  <- df %>% filter(control   == 1)
  base  <- df %>% filter(GPT_base  == 1)
  tutor <- df %>% filter(GPT_tutor == 1)

  tests <- rbind(
    perform_ttest(ctrl$scores_assisted,  base$scores_assisted,
                  "Control vs. GPT Base (Assisted)"),
    perform_ttest(ctrl$scores_assisted,  tutor$scores_assisted,
                  "Control vs. GPT Tutor (Assisted)"),
    perform_ttest(ctrl$scores_unassisted, base$scores_unassisted,
                  "Control vs. GPT Base (Unassisted)"),
    perform_ttest(ctrl$scores_unassisted, tutor$scores_unassisted,
                  "Control vs. GPT Tutor (Unassisted)"),
    perform_ttest(ctrl$scores_unassisted, ctrl$scores_assisted,
                  "Control: Unassisted vs. Assisted"),
    perform_ttest(base$scores_unassisted, base$scores_assisted,
                  "GPT Base: Unassisted vs. Assisted"),
    perform_ttest(tutor$scores_unassisted, tutor$scores_assisted,
                  "GPT Tutor: Unassisted vs. Assisted")
  )
  rownames(tests) <- NULL
  tests
}

format_ttest_table <- function(tests) {
  kable(
    tests,
    col.names = c("Test", "t-statistic", "df", "p-value", "Mean Difference"),
    caption   = "T-Test Results",
    align     = c("l", "r", "r", "r", "r")
  )
}
