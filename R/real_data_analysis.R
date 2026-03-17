# real_data_analysis.R — P0: Main regression, covariate balance, moderator analysis
# Uses author-shared final_data.csv from GenAICanHarmLearning repository

library(here)
library(dplyr)
library(tidyr)
library(sandwich)
library(lmtest)
library(ggplot2)
library(knitr)
library(broom)

# Paths
FINAL_DATA_PATH <- here("..", "GenAICanHarmLearning", "main_regressions", "final_data.csv")
OUTPUT_TABLES  <- here("outputs", "tables")
OUTPUT_FIGURES <- here("outputs", "figures")

# Ensure output dirs exist
dir.create(OUTPUT_TABLES,  showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_FIGURES, showWarnings = FALSE, recursive = TRUE)

# --- Load and prepare data ---
load_real_data <- function() {
  df <- read.csv(FINAL_DATA_PATH)
  df <- df[df$Honors == 0, ]
  df$teacher  <- as.factor(df$teacher)
  df$Session  <- as.factor(df$Session)
  df$Year     <- as.factor(df$Year)
  df$Grader   <- as.factor(df$Grader)
  df
}

# --- 1. Main regression (reproduce paper) ---
run_main_regression <- function(df) {
  reg2 <- lm(Part2Tot ~ GPTBase + GPTTutor + gpa_prev +
               teacher + Session + Grader + Year, data = df)
  reg3 <- lm(Part3Tot ~ GPTBase + GPTTutor + gpa_prev +
               teacher + Session + Grader + Year, data = df)
  se2 <- sqrt(diag(vcovCL(reg2, cluster = ~ Class)))
  se3 <- sqrt(diag(vcovCL(reg3, cluster = ~ Class)))
  list(assisted = reg2, unassisted = reg3, se_assisted = se2, se_unassisted = se3)
}

format_main_regression_table <- function(regs, df) {
  coef_names <- c("GPTBase", "GPTTutor", "gpa_prev")
  tbl <- data.frame(
    Outcome    = c(rep("Assisted (Part 2)", 3), rep("Unassisted (Part 3)", 3)),
    Coefficient = rep(c("GPT Base", "GPT Tutor", "Prior GPA"), 2),
    Estimate   = c(
      coef(regs$assisted)[coef_names],
      coef(regs$unassisted)[coef_names]
    ),
    SE         = c(
      regs$se_assisted[coef_names],
      regs$se_unassisted[coef_names]
    )
  )
  tbl$CI_lower <- tbl$Estimate - 1.96 * tbl$SE
  tbl$CI_upper <- tbl$Estimate + 1.96 * tbl$SE
  # Use cluster-level degrees of freedom (n_clusters - 1) to match paper's inference
  n_clusters <- length(unique(df$Class))
  t_stats_a  <- coef(regs$assisted)[coef_names]  / regs$se_assisted[coef_names]
  t_stats_u  <- coef(regs$unassisted)[coef_names] / regs$se_unassisted[coef_names]
  tbl$p_value <- c(
    2 * pt(-abs(t_stats_a), df = n_clusters - 1),
    2 * pt(-abs(t_stats_u), df = n_clusters - 1)
  )
  tbl
}

# --- 2. Covariate balance (one row per student) ---
balance_vars <- c("gpa_prev", "female", "n_weekday_study_hours", "n_weekend_study_hours",
                  "private_tutorship", "chatgpt_use")

compute_balance <- function(df) {
  # One row per student (first observation)
  sid_col <- names(df)[1]
  df1 <- df[!duplicated(df[[sid_col]]), ]
  df1$arm <- case_when(
    df1$GPTBase == 1 ~ "GPT Base",
    df1$GPTTutor == 1 ~ "GPT Tutor",
    TRUE ~ "Control"
  )
  df1$arm <- factor(df1$arm, levels = c("Control", "GPT Base", "GPT Tutor"))

  # Numeric conversion for balance vars
  for (v in balance_vars) {
    if (v %in% names(df1)) df1[[v]] <- as.numeric(df1[[v]])
  }

  # Means and SDs by arm
  ctrl <- df1[df1$arm == "Control", ]
  base <- df1[df1$arm == "GPT Base", ]
  tutor <- df1[df1$arm == "GPT Tutor", ]

  out <- data.frame(
    Variable = balance_vars,
    Control_mean = sapply(balance_vars, function(v) mean(ctrl[[v]], na.rm = TRUE)),
    GPTBase_mean = sapply(balance_vars, function(v) mean(base[[v]], na.rm = TRUE)),
    GPTTutor_mean = sapply(balance_vars, function(v) mean(tutor[[v]], na.rm = TRUE)),
    Control_sd   = sapply(balance_vars, function(v) sd(ctrl[[v]], na.rm = TRUE)),
    GPTBase_sd   = sapply(balance_vars, function(v) sd(base[[v]], na.rm = TRUE)),
    GPTTutor_sd  = sapply(balance_vars, function(v) sd(tutor[[v]], na.rm = TRUE))
  )

  # Standardized mean difference: (mean_treat - mean_ctrl) / pooled_sd
  pooled_sd_base  <- sqrt((out$Control_sd^2 + out$GPTBase_sd^2) / 2)
  pooled_sd_tutor <- sqrt((out$Control_sd^2 + out$GPTTutor_sd^2) / 2)
  out$SMD_Base   <- (out$GPTBase_mean - out$Control_mean) / ifelse(pooled_sd_base > 0, pooled_sd_base, 1)
  out$SMD_Tutor  <- (out$GPTTutor_mean - out$Control_mean) / ifelse(pooled_sd_tutor > 0, pooled_sd_tutor, 1)
  out
}

plot_love_plot <- function(bal) {
  bal_long <- bal %>%
    select(Variable, SMD_Base, SMD_Tutor) %>%
    tidyr::pivot_longer(cols = c(SMD_Base, SMD_Tutor),
                        names_to = "Arm", values_to = "SMD") %>%
    mutate(Arm = recode(Arm, SMD_Base = "GPT Base", SMD_Tutor = "GPT Tutor"))

  # Variable labels
  labels <- c(
    gpa_prev = "Prior GPA",
    female = "Female",
    n_weekday_study_hours = "Weekday study hrs",
    n_weekend_study_hours = "Weekend study hrs",
    private_tutorship = "Private tutoring",
    chatgpt_use = "Prior ChatGPT use"
  )
  bal_long$Variable_label <- labels[bal_long$Variable]

  ggplot(bal_long, aes(x = SMD, y = reorder(Variable_label, abs(SMD)), color = Arm, shape = Arm)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = c(-0.1, 0.1), linetype = "dotted", color = "gray70") +
    geom_point(size = 3, position = position_dodge(width = 0.3)) +
    scale_color_manual(values = c("GPT Base" = "#E57373", "GPT Tutor" = "#81C784")) +
    scale_shape_manual(values = c("GPT Base" = 16, "GPT Tutor" = 17)) +
    labs(
      title = "Covariate Balance: Standardized Mean Differences",
      subtitle = "Control vs. GPT Base and GPT Tutor; dotted lines = ±0.1",
      x = "Standardized Mean Difference",
      y = NULL,
      color = "Treatment", shape = "Treatment"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank())
}

# --- 3. Moderator: heterogeneity by prior GPA and ChatGPT use ---
run_moderator_analysis <- function(df) {
  # Median split on gpa_prev
  df$gpa_high <- as.integer(df$gpa_prev >= median(df$gpa_prev, na.rm = TRUE))
  # Binary ChatGPT use (0 vs any prior use)
  df$chatgpt_any <- as.integer(df$chatgpt_use > 0)

  # Heterogeneity by gpa_prev (interaction)
  reg_gpa_a <- lm(Part2Tot ~ GPTBase * gpa_high + GPTTutor * gpa_high + gpa_prev +
                    teacher + Session + Grader + Year, data = df)
  reg_gpa_u <- lm(Part3Tot ~ GPTBase * gpa_high + GPTTutor * gpa_high + gpa_prev +
                    teacher + Session + Grader + Year, data = df)
  se_gpa_a <- sqrt(diag(vcovCL(reg_gpa_a, cluster = ~ Class)))
  se_gpa_u <- sqrt(diag(vcovCL(reg_gpa_u, cluster = ~ Class)))

  # Heterogeneity by chatgpt_any (interaction)
  df_chat <- df[!is.na(df$chatgpt_any) & df$chatgpt_any %in% c(0, 1), ]
  reg_chat_a <- lm(Part2Tot ~ GPTBase * chatgpt_any + GPTTutor * chatgpt_any + gpa_prev +
                     teacher + Session + Grader + Year, data = df_chat)
  reg_chat_u <- lm(Part3Tot ~ GPTBase * chatgpt_any + GPTTutor * chatgpt_any + gpa_prev +
                     teacher + Session + Grader + Year, data = df_chat)
  se_chat_a <- sqrt(diag(vcovCL(reg_chat_a, cluster = ~ Class)))
  se_chat_u <- sqrt(diag(vcovCL(reg_chat_u, cluster = ~ Class)))

  list(
    gpa = list(assisted = reg_gpa_a, unassisted = reg_gpa_u,
               se_a = se_gpa_a, se_u = se_gpa_u),
    chatgpt = list(assisted = reg_chat_a, unassisted = reg_chat_u,
                   se_a = se_chat_a, se_u = se_chat_u)
  )
}

format_moderator_table <- function(mods) {
  coefs_gpa <- c("GPTBase", "GPTTutor", "gpa_high", "GPTBase:gpa_high", "GPTTutor:gpa_high")
  coefs_chat <- c("GPTBase", "GPTTutor", "chatgpt_any", "GPTBase:chatgpt_any", "GPTTutor:chatgpt_any")
  label <- c(
    GPTBase = "GPT Base", GPTTutor = "GPT Tutor", gpa_high = "High prior GPA",
    "GPTBase:gpa_high" = "GPT Base × High GPA", "GPTTutor:gpa_high" = "GPT Tutor × High GPA",
    chatgpt_any = "Prior ChatGPT use",
    "GPTBase:chatgpt_any" = "GPT Base × ChatGPT use", "GPTTutor:chatgpt_any" = "GPT Tutor × ChatGPT use"
  )

  gpa_a <- tidy(mods$gpa$assisted) %>% filter(term %in% coefs_gpa) %>% mutate(moderator = "Prior GPA", outcome = "Assisted")
  gpa_u <- tidy(mods$gpa$unassisted) %>% filter(term %in% coefs_gpa) %>% mutate(moderator = "Prior GPA", outcome = "Unassisted")
  chat_a <- tidy(mods$chatgpt$assisted) %>% filter(term %in% coefs_chat) %>% mutate(moderator = "ChatGPT use", outcome = "Assisted")
  chat_u <- tidy(mods$chatgpt$unassisted) %>% filter(term %in% coefs_chat) %>% mutate(moderator = "ChatGPT use", outcome = "Unassisted")

  tbl <- rbind(gpa_a, gpa_u, chat_a, chat_u) %>%
    select(moderator, outcome, term, estimate, std.error, p.value) %>%
    mutate(term_label = label[term])
  tbl
}

# --- Run all and save ---
run_real_data_analysis <- function() {
  df <- load_real_data()

  # 1. Main regression
  regs <- run_main_regression(df)
  tbl_main <- format_main_regression_table(regs, df)
  write.csv(tbl_main, file.path(OUTPUT_TABLES, "main_regression_coefficients.csv"), row.names = FALSE)

  # 2. Balance
  bal <- compute_balance(df)
  write.csv(bal, file.path(OUTPUT_TABLES, "covariate_balance.csv"), row.names = FALSE)
  key_vars <- c("gpa_prev", "private_tutorship", "chatgpt_use")
  p_love <- plot_love_plot(bal[bal$Variable %in% key_vars, ])
  ggsave(file.path(OUTPUT_FIGURES, "love_plot_balance.png"), p_love, width = 7, height = 3.5, dpi = 150)

  # 3. Moderator
  mods <- run_moderator_analysis(df)
  tbl_mod <- format_moderator_table(mods)
  write.csv(tbl_mod, file.path(OUTPUT_TABLES, "moderator_heterogeneity.csv"), row.names = FALSE)

  # Coefficient plot for main effects
  tbl_plot <- tbl_main %>% filter(Coefficient %in% c("GPT Base", "GPT Tutor"))
  p_coef <- ggplot(tbl_plot, aes(x = Estimate, y = Coefficient, color = Outcome)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbar(aes(xmin = CI_lower, xmax = CI_upper), width = 0.2, linewidth = 0.8, orientation = "y") +
    geom_point(size = 3) +
    scale_color_manual(values = c("Assisted (Part 2)" = "#64B5F6", "Unassisted (Part 3)" = "#E57373")) +
    labs(title = "Treatment Effects: Author-Shared Data",
         subtitle = "Clustered SE by Class; 95% CI",
         x = "Coefficient (vs. Control)", y = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
  ggsave(file.path(OUTPUT_FIGURES, "coefficient_plot_main.png"), p_coef, width = 7, height = 4, dpi = 150)

  list(
    regression_table = tbl_main,
    balance_table = bal,
    love_plot = p_love,
    coefficient_plot = p_coef,
    moderator_table = tbl_mod
  )
}
