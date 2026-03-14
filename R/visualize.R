# visualize.R — Plotting functions

library(ggplot2)
library(ggridges)
library(tidyr)
library(dplyr)

GROUP_COLORS <- c(
  "Control"   = "skyblue",
  "GPT Base"  = "lightgreen",
  "GPT Tutor" = "lightcoral"
)

ASSIST_COLORS <- c(
  "Assisted"   = "steelblue",
  "Unassisted" = "lightcoral"
)

prepare_long_data <- function(df) {
  df %>%
    pivot_longer(
      cols      = c(scores_assisted, scores_unassisted),
      names_to  = "assistance",
      values_to = "score"
    ) %>%
    mutate(
      group = case_when(
        control   == 1 ~ "Control",
        GPT_base  == 1 ~ "GPT Base",
        GPT_tutor == 1 ~ "GPT Tutor"
      ),
      assistance = factor(
        recode(assistance,
               scores_assisted   = "Assisted",
               scores_unassisted = "Unassisted"),
        levels = c("Assisted", "Unassisted")
      )
    )
}

plot_crutch_effect <- function(long_data) {
  means <- long_data %>%
    group_by(group, assistance) %>%
    summarize(mean_score = mean(score),
              se = sd(score) / sqrt(n()),
              .groups = "drop")

  ctrl_unassisted  <- means$mean_score[means$group == "Control" &
                                        means$assistance == "Unassisted"]
  base_unassisted  <- means$mean_score[means$group == "GPT Base" &
                                        means$assistance == "Unassisted"]
  tutor_unassisted <- means$mean_score[means$group == "GPT Tutor" &
                                        means$assistance == "Unassisted"]

  base_vs_ctrl_pct <- round((ctrl_unassisted - base_unassisted) /
                              ctrl_unassisted * 100)

  ggplot() +
    geom_hline(yintercept = ctrl_unassisted, linetype = "dashed",
               color = "grey40", linewidth = 0.5) +
    annotate("text", x = 0.65, y = ctrl_unassisted + 0.012,
             label = "Control baseline (unassisted)",
             size = 3, color = "grey40", hjust = 0) +
    geom_jitter(data = long_data,
                aes(x = assistance, y = score, color = group),
                alpha = 0.06, width = 0.08, size = 0.8) +
    geom_line(data = means,
              aes(x = assistance, y = mean_score, group = group, color = group),
              linewidth = 1.4) +
    geom_errorbar(data = means,
                  aes(x = assistance, y = mean_score,
                      ymin = mean_score - 1.96 * se,
                      ymax = mean_score + 1.96 * se,
                      color = group),
                  width = 0.08, linewidth = 0.7) +
    geom_point(data = means,
               aes(x = assistance, y = mean_score, color = group),
               size = 4.5) +
    annotate("label", x = 1.75, y = base_unassisted - 0.04,
             label = paste0("GPT Base: ", base_vs_ctrl_pct,
                            "% below control (p < 0.001)"),
             size = 3, fill = "#FFF3E0", fontface = "bold",
             label.size = 0.4) +
    annotate("label", x = 1.75, y = tutor_unassisted + 0.06,
             label = "GPT Tutor: at control baseline (n.s.)",
             size = 3, fill = "#E8F5E9", fontface = "bold",
             label.size = 0.4) +
    scale_color_manual(values = c("Control"   = "#64B5F6",
                                  "GPT Base"  = "#E57373",
                                  "GPT Tutor" = "#81C784")) +
    scale_x_discrete(expand = expansion(mult = c(0.05, 0.1))) +
    labs(title = "The Crutch Effect: AI Boosts Assisted Scores but GPT Base Harms Unassisted Learning",
         subtitle = "Mean scores with 95% CI; dashed line = Control unassisted baseline",
         x = NULL, y = "Normalized Score (0\u20131)",
         color = "Group") +
    theme_minimal(base_size = 13) +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 12))
}

plot_boxplots_faceted <- function(long_data) {
  ggplot(long_data, aes(x = group, y = score, fill = group)) +
    geom_boxplot(alpha = 0.7) +
    facet_wrap(~ assistance, ncol = 2) +
    scale_fill_manual(values = GROUP_COLORS) +
    labs(title = "Score Distributions by Group (Assisted vs. Unassisted)",
         x = "Group", y = "Score") +
    theme_minimal() +
    theme(legend.position = "none",
          strip.text = element_text(face = "bold"))
}

plot_boxplots_dodged <- function(long_data) {
  ggplot(long_data, aes(x = group, y = score, fill = assistance)) +
    geom_boxplot(position = position_dodge(width = 0.8), alpha = 0.7) +
    scale_fill_manual(values = ASSIST_COLORS) +
    labs(title = "Score Distributions by Group and Assistance Level",
         x = "Group", y = "Score", fill = "Assistance Level") +
    theme_minimal() +
    theme(strip.text = element_text(face = "bold"))
}

plot_histograms_grid <- function(long_data) {
  ggplot(long_data, aes(x = score, fill = group)) +
    geom_histogram(binwidth = 0.05, color = "steelblue",
                   fill = "skyblue", position = "stack") +
    facet_grid(group ~ assistance) +
    labs(title = "Score Distributions by Group and Assistance Level",
         x = "Score", y = "Frequency") +
    theme_minimal() +
    theme(strip.text = element_text(face = "bold"), legend.position = "none")
}

plot_histograms_overlaid <- function(long_data) {
  long_data %>%
    ggplot(aes(score, fill = assistance)) +
    geom_histogram(binwidth = 0.025, color = "steelblue", alpha = 0.7) +
    facet_grid(group ~ .) +
    scale_x_continuous(limits = c(0, 1)) +
    scale_fill_manual(values = c("Assisted" = "skyblue",
                                 "Unassisted" = "lightcoral")) +
    labs(title = "Score Distribution by Group and Assistance Level",
         x = "Score", y = "Frequency", fill = "Assistance Level") +
    theme_minimal() +
    theme(strip.text = element_text(face = "bold"))
}

plot_ridge <- function(long_data) {
  ggplot(long_data, aes(x = score, y = group,
                        fill = assistance, height = after_stat(density))) +
    geom_density_ridges(alpha = 0.6, scale = 0.5) +
    scale_fill_manual(values = c("Assisted" = "skyblue",
                                 "Unassisted" = "lightcoral")) +
    scale_x_continuous(limits = c(0, 1)) +
    labs(title = "Score Distribution by Group and Assistance Level",
         x = "Score", y = "Group", fill = "Assistance Level") +
    theme_minimal() +
    theme(strip.text = element_text(face = "bold"))
}
