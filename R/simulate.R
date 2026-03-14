# simulate.R — Functions to generate the simulated RCT dataset

library(truncnorm)
library(dplyr)

source(here::here("R", "config.R"))

simulate_students <- function(seed = SEED) {
  set.seed(seed)

  prev_gpa  <- rtruncnorm(N_STUDENTS, a = 0, b = 1, mean = MEAN_GPA, sd = SD_GPA)
  class_ids <- rep(1:N_CLASSES, each = STUDENTS_PER_CLASS)

  treatment <- sample(
    c("GPT_base", "GPT_tutor", "control"),
    N_CLASSES,
    replace = TRUE,
    prob = c(PROB_BASE, PROB_TUTOR, PROB_CONTROL)
  )

  data.frame(
    student_id = 1:N_STUDENTS,
    class_id   = class_ids,
    GPT_base   = rep(as.integer(treatment == "GPT_base"),  each = STUDENTS_PER_CLASS),
    GPT_tutor  = rep(as.integer(treatment == "GPT_tutor"), each = STUDENTS_PER_CLASS),
    control    = rep(as.integer(treatment == "control"),    each = STUDENTS_PER_CLASS),
    prev_gpa   = prev_gpa
  )
}

simulate_classroom_betas <- function(class_ids) {
  n <- length(class_ids)
  data.frame(
    class_id                = class_ids,
    beta_base_assisted      = rnorm(n, BETA_BASE_ASSISTED$mean,    BETA_BASE_ASSISTED$sd),
    beta_tutor_assisted     = rnorm(n, BETA_TUTOR_ASSISTED$mean,   BETA_TUTOR_ASSISTED$sd),
    beta_prevGPA_assisted   = rnorm(n, BETA_GPA_ASSISTED$mean,     BETA_GPA_ASSISTED$sd),
    beta_base_unassisted    = rnorm(n, BETA_BASE_UNASSISTED$mean,  BETA_BASE_UNASSISTED$sd),
    beta_tutor_unassisted   = rnorm(n, BETA_TUTOR_UNASSISTED$mean, BETA_TUTOR_UNASSISTED$sd),
    beta_prevGPA_unassisted = rnorm(n, BETA_GPA_UNASSISTED$mean,   BETA_GPA_UNASSISTED$sd)
  )
}

simulate_scores <- function(df) {
  df %>%
    mutate(
      scores_assisted = ifelse(
        control == 1,
        rnorm(n(), mean = CONTROL_MEAN_ASSISTED, sd = SCORE_NOISE_SD),
        CONTROL_MEAN_ASSISTED +
          beta_base_assisted  * GPT_base +
          beta_tutor_assisted * GPT_tutor +
          rnorm(n(), mean = 0, sd = SCORE_NOISE_SD)
      ),
      scores_unassisted = ifelse(
        control == 1,
        rnorm(n(), mean = CONTROL_MEAN_UNASSISTED, sd = SCORE_NOISE_SD),
        CONTROL_MEAN_UNASSISTED +
          beta_base_unassisted  * GPT_base +
          beta_tutor_unassisted * GPT_tutor +
          rnorm(n(), mean = 0, sd = SCORE_NOISE_SD)
      )
    )
}

generate_simulated_data <- function(seed = SEED) {
  set.seed(seed)

  students <- simulate_students(seed)
  betas    <- simulate_classroom_betas(unique(students$class_id))
  merged   <- merge(students, betas, by = "class_id")

  simulate_scores(merged)
}
