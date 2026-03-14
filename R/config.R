# config.R — Simulation parameters from the original Wharton study
# Bastani et al. (2024), "Generative AI Can Harm Learning"

SEED <- 4

# --- Study design ---
N_CLASSES <- 50
STUDENTS_PER_CLASS <- 20
N_STUDENTS <- N_CLASSES * STUDENTS_PER_CLASS

# Treatment assignment probabilities (from Table 3)
PROB_BASE    <- 242 / 839
PROB_TUTOR   <- 277 / 839
PROB_CONTROL <- 320 / 839

# --- Prior GPA distribution ---
MEAN_GPA <- 0.82
SD_GPA   <- 0.11

# --- Control group score distributions ---
CONTROL_MEAN_ASSISTED   <- 0.284
CONTROL_SD_ASSISTED     <- 0.287
CONTROL_MEAN_UNASSISTED <- 0.321
CONTROL_SD_UNASSISTED   <- 0.277

# --- Treatment effect coefficients (mean, SE) ---
BETA_BASE_ASSISTED    <- list(mean = 0.137, sd = 0.031)
BETA_BASE_UNASSISTED  <- list(mean = -0.054, sd = 0.022)
BETA_TUTOR_ASSISTED   <- list(mean = 0.361, sd = 0.032)
BETA_TUTOR_UNASSISTED <- list(mean = -0.004, sd = 0.013)
BETA_GPA_ASSISTED     <- list(mean = 0.802, sd = 0.076)
BETA_GPA_UNASSISTED   <- list(mean = 1.334, sd = 0.069)

# --- Noise added to individual scores ---
SCORE_NOISE_SD <- 0.05
