# power_analysis.R — Post-hoc power analysis for the cluster-randomized design

library(dplyr)
library(ggplot2)
library(knitr)

source(here::here("R", "config.R"))

compute_mde <- function(sigma, J_t, J_c, m, icc, alpha = 0.05, power = 0.80) {
  deff <- 1 + (m - 1) * icc
  n_t  <- J_t * m
  n_c  <- J_c * m
  se   <- sigma * sqrt(deff) * sqrt(1 / n_t + 1 / n_c)
  df   <- J_t + J_c - 2
  (qt(1 - alpha / 2, df) + qt(power, df)) * se
}

compute_icc <- function(scores, class_ids, m) {
  aov_result <- aov(scores ~ factor(class_ids))
  ms   <- summary(aov_result)[[1]][["Mean Sq"]]
  ms_b <- ms[1]
  ms_w <- ms[2]
  max((ms_b - ms_w) / (ms_b + (m - 1) * ms_w), 0)
}

run_power_analysis <- function(simulated_df = NULL,
                               icc_values = seq(0.01, 0.25, by = 0.01)) {
  J_base    <- round(N_CLASSES * PROB_BASE)
  J_tutor   <- round(N_CLASSES * PROB_TUTOR)
  J_control <- round(N_CLASSES * PROB_CONTROL)
  m         <- STUDENTS_PER_CLASS

  observed <- data.frame(
    comparison = c("GPT Base (Assisted)",  "GPT Tutor (Assisted)",
                   "GPT Base (Unassisted)","GPT Tutor (Unassisted)"),
    effect     = c(BETA_BASE_ASSISTED$mean,  BETA_TUTOR_ASSISTED$mean,
                   abs(BETA_BASE_UNASSISTED$mean), abs(BETA_TUTOR_UNASSISTED$mean)),
    stringsAsFactors = FALSE
  )

  grid <- expand.grid(icc = icc_values, comparison = observed$comparison,
                      stringsAsFactors = FALSE)

  grid$mde <- mapply(function(icc, comp) {
    sigma <- if (grepl("Unassisted", comp)) CONTROL_SD_UNASSISTED else CONTROL_SD_ASSISTED
    J_t   <- if (grepl("Base", comp)) J_base else J_tutor
    compute_mde(sigma, J_t, J_control, m, icc)
  }, grid$icc, grid$comparison)

  grid <- merge(grid, observed, by = "comparison")
  grid$powered <- grid$effect >= grid$mde

  icc_est <- NULL
  if (!is.null(simulated_df)) {
    icc_est <- list(
      assisted   = compute_icc(simulated_df$scores_assisted,
                               simulated_df$class_id, m),
      unassisted = compute_icc(simulated_df$scores_unassisted,
                               simulated_df$class_id, m)
    )
  }

  key_iccs <- c(0.05, 0.10, 0.15, 0.20)
  summary_tbl <- grid %>%
    filter(icc %in% key_iccs) %>%
    mutate(mde    = round(mde, 3),
           effect = round(effect, 3),
           powered = ifelse(powered, "Yes", "No")) %>%
    select(Comparison = comparison, ICC = icc,
           MDE = mde, Observed = effect, Powered = powered) %>%
    arrange(Comparison, ICC)

  list(grid = grid, summary = summary_tbl, icc_est = icc_est,
       design = list(J_base = J_base, J_tutor = J_tutor,
                     J_control = J_control, m = m))
}

plot_power_curves <- function(pa) {
  ggplot(pa$grid, aes(x = icc, y = mde, color = comparison)) +
    geom_line(linewidth = 1) +
    geom_hline(data = pa$grid %>% distinct(comparison, effect),
               aes(yintercept = effect, color = comparison),
               linetype = "dashed", alpha = 0.7) +
    scale_x_continuous(labels = function(x) paste0(x * 100, "%"),
                       limits = c(0, 0.25)) +
    labs(title    = "Minimum Detectable Effect vs. Intraclass Correlation",
         subtitle = "Dashed lines = observed effects from Bastani et al. (2024)",
         x = "ICC (Intraclass Correlation)",
         y = "Minimum Detectable Effect",
         color = "Comparison") +
    theme_minimal() +
    theme(legend.position = "bottom",
          legend.title = element_text(face = "bold"))
}

format_power_table <- function(pa) {
  kable(pa$summary,
        caption = "Minimum Detectable Effects at 80% Power, \u03b1 = 0.05",
        align   = c("l", "r", "r", "r", "c"))
}
