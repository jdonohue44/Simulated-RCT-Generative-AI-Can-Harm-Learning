# packages, seed

library(truncnorm)
library(lmtest)
library(dplyr)
library(ggplot2)
library(ggridges)
library(tidyr)

set.seed(4)

##### information provided in the paper / setup
n_classes <- 50
students_per_class <- 20
n_students <- n_classes * students_per_class
mean_gpa <- 0.82
sd_gpa <- 0.11

control_mean_assisted <- 0.284
control_sd_assisted <- 0.287

control_mean_unassisted <- 0.321
control_sd_unassisted <- 0.277

beta_base_mean_assisted <- 0.137
beta_base_sd_assisted <- 0.031

beta_base_mean_unassisted <- -0.054
beta_base_sd_unassisted <- 0.022
  
beta_tutor_mean_assisted <- 0.361
beta_tutor_sd_assisted <- 0.032

beta_tutor_mean_unassisted <- -0.004
beta_tutor_sd_unassisted <- 0.013

beta_prevGPA_mean_assisted <- 0.802
beta_prevGPA_sd_assisted <- 0.076

beta_prevGPA_mean_unassisted <- 1.334
beta_prevGPA_sd_unassisted <- 0.069

# random assignment of class ids
class_ids <- rep(1:n_classes, each = students_per_class)
student_ids <- 1:n_students

# gpa data simulation
prev_gpa <- rtruncnorm(n_students, a = 0, b = 1, mean = mean_gpa, sd = sd_gpa)

# assign treatment
# probabilities from table 3
prob_base <- 242 / 839
prob_tutor <- 277 / 839
prob_control <- 320 / 839

treatment_assignment <- sample(c("GPT_base", "GPT_tutor", "control"), prob = c(prob_base,prob_tutor,prob_control), n_classes, replace = TRUE)

GPT_base_class <- as.integer(treatment_assignment == "GPT_base")
GPT_tutor_class <- as.integer(treatment_assignment == "GPT_tutor")
control_class <- as.integer(treatment_assignment == "control")

GPT_base <- rep(GPT_base_class, each = students_per_class)
GPT_tutor <- rep(GPT_tutor_class, each = students_per_class)
control <- rep(control_class, each = students_per_class)

# fixed effects (not 100% on this one)
sessions <- sample(1:4, n_students, replace = TRUE)
grade_levels <- sample(9:12, n_students, replace = TRUE) 
teachers <- sample(1:20, n_students, replace = TRUE)
graders <- sample(1:10, n_students, replace = TRUE)

simulated_data <- data.frame(
  student_id = student_ids,
  class_id = class_ids,
  GPT_base = GPT_base,
  GPT_tutor = GPT_tutor,
  control = control,
  prev_gpa = prev_gpa)

##### simulation of scores data

# NOTE: I am leaving out fixed effects and GPA. We can mention that leaving out fixed effects would be likely to bias the data if we
# were the ones coming up with the regression, but to reverse engineer the scores, it adds too much complexity because the paper
# gives very minimal information on how they calculate that.

# GPA I am happy to add back in but I am kind of confused whether they are adding it to the control or not?

simulated_betas <- data.frame(
  class_id = unique(simulated_data$class_id),
  beta_base_assisted = rnorm(length(unique(simulated_data$class_id)), beta_base_mean_assisted, beta_base_sd_assisted),
  beta_tutor_assisted = rnorm(length(unique(simulated_data$class_id)), beta_tutor_mean_assisted, beta_tutor_sd_assisted),
  beta_prevGPA_assisted = rnorm(length(unique(simulated_data$class_id)), beta_prevGPA_mean_assisted, beta_prevGPA_sd_assisted),
  beta_base_unassisted = rnorm(length(unique(simulated_data$class_id)), beta_base_mean_unassisted, beta_base_sd_unassisted),
  beta_tutor_unassisted = rnorm(length(unique(simulated_data$class_id)), beta_tutor_mean_unassisted, beta_tutor_sd_unassisted),
  beta_prevGPA_unassisted = rnorm(length(unique(simulated_data$class_id)), beta_prevGPA_mean_unassisted, beta_prevGPA_sd_unassisted)
)

simulated_data_with_betas <- merge(simulated_data, simulated_betas, by = "class_id")

simulated_data_with_betas <- simulated_data_with_betas %>%
  mutate(
    scores_assisted = ifelse(
      control == 1,
      rnorm(n(), mean = control_mean_assisted, sd = 0.05),
      control_mean_assisted +
        beta_base_assisted * GPT_base +
        beta_tutor_assisted * GPT_tutor +
        rnorm(n(), mean = 0, sd = 0.05)
    )
  )

simulated_data_with_betas <- simulated_data_with_betas %>%
  mutate(
    scores_unassisted = ifelse(
      control == 1,
      rnorm(n(), mean = control_mean_unassisted, sd = 0.05),
      control_mean_unassisted +
        beta_base_unassisted * GPT_base +
        beta_tutor_unassisted * GPT_tutor +
        rnorm(n(), mean = 0, sd = 0.05)
    )
  )

# run regressions to confirm they look similar to table 1 - would still need some actual statistical tests
reg_assisted <- lm(scores_assisted ~ GPT_base + GPT_tutor + prev_gpa, data = simulated_data_with_betas)
summary(reg_assisted)

reg_unassisted <- lm(scores_unassisted ~ GPT_base + GPT_tutor + prev_gpa, data = simulated_data_with_betas)
summary(reg_unassisted)

write.csv(simulated_data_with_betas,'./simulated_data', row.names = FALSE)

head(simulated_data_with_betas)


############### GRAPHS ###############

# transform data so it's easier to use with ggplot
long_data <- simulated_data_with_betas %>%
  pivot_longer(
    cols = c(scores_assisted, scores_unassisted),
    names_to = "assistance",
    values_to = "score"
  ) %>%
  mutate(
    group = case_when(
      control == 1 ~ "Control",
      GPT_base == 1 ~ "GPT Base",
      GPT_tutor == 1 ~ "GPT Tutor"
    ),
    assistance = recode(assistance, 
                        scores_assisted = "Assisted", 
                        scores_unassisted = "Unassisted")
  )

# this one splits it up into assisted vs unassisted as the larger groups
# makes it easier to see the groups compared to each other
plot1 <- ggplot(long_data, aes(x = group, y = score, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~ assistance, ncol = 2) +
  labs(
    title = "Score Distributions by Group (Assisted vs. Unassisted)",
    x = "Group",
    y = "Score"
  ) +
  scale_fill_manual(
    values = c("Control" = "skyblue", "GPT Base" = "lightgreen", "GPT Tutor" = "lightcoral")
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )

ggsave("./boxplot1.png", 
       plot = plot1, width = 8, height = 6, dpi = 300)


# this one splits it up by treatment as the larger group
# i think the first one is more valuable but included this just in case
plot2 <- ggplot(long_data, aes(x = group, y = score, fill = assistance)) +
  geom_boxplot(position = position_dodge(width = 0.8), alpha = 0.7) +
  labs(
    title = "Score Distributions by Group and Assistance Level",
    x = "Group",
    y = "Score",
    fill = "Assistance Level"
  ) +
  scale_fill_manual(
    values = c("Assisted" = "steelblue", "Unassisted" = "lightcoral")
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold")
  )

ggsave("./boxplot2.png", 
       plot = plot2, width = 8, height = 6, dpi = 300)


## faceted histogram 
ggplot(long_data, aes(x = score, fill = group)) +
  geom_histogram(binwidth = 0.05, 
                 color = "steelblue", 
                 fill = "skyblue", 
                 position = "stack") +
  facet_grid(group ~ assistance) + 
  labs(
    title = "Score Distributions by Group and Assistance Level",
    x = "Score",
    y = "Frequency"
  ) + 
  theme_minimal() + 
  theme(
    strip.text = element_text(face = "bold"),
    legend.position = "none"
  )

#vertical histograms

long_data_assist <- long_data %>% 
  filter(assistance == 'Assisted')

long_data_assist %>% ggplot(aes(score)) +
  geom_histogram(binwidth = .05,
                 color = 'steelblue',
                 fill = 'skyblue') +
  scale_x_continuous(limits = c(0, 1)) +
  facet_grid(group ~ .)

long_data_unassist <- long_data %>%
  filter(assistance == 'Unassisted')


long_data_unassist %>% ggplot(aes(score)) +
  geom_histogram(binwidth = .05,
                 color = 'lightcoral',
                 fill = 'lightpink') +
  scale_x_continuous(limits = c(0, 1)) +
  facet_grid(group ~ .)

# assisted and unassisted data together on same axis

long_data_combined <- long_data %>%
  filter(assistance %in% c('Assisted', 'Unassisted'))

plot3 <- long_data_combined %>%
  ggplot(aes(score, fill = assistance)) + 
  geom_histogram(binwidth = 0.025, 
                 color = 'steelblue', 
                 alpha = 0.7) +  
  facet_grid(group ~ .) +  
  scale_x_continuous(limits = c(0, 1)) +  
  scale_fill_manual(values = c('Assisted' = 'skyblue', 'Unassisted' = 'lightcoral')) +  # Colors for assisted and unassisted
  labs(title = "Score Distribution by Group and Assistance Level", 
       x = "Score", 
       y = "Frequency", 
       fill = "Assistance Level") +
  theme_minimal() + 
  theme(strip.text = element_text(face = "bold"))

ggsave("./histograms_combined.png", 
       plot = plot3, width = 8, height = 6, dpi = 300)

#ridgeline plot 

long_data_combined %>%
  ggplot(aes(x = score, y = group, fill = assistance, height = ..density..)) + 
  geom_density_ridges(
    alpha = 0.6, 
    scale = .5) +  
  scale_fill_manual(values = c('Assisted' = 'skyblue', 'Unassisted' = 'lightcoral')) +  # Colors for assisted and unassisted
  scale_x_continuous(limits = c(0, 1)) +  # Set x-axis range from 0 to 1
  labs(title = "Score Distribution by Group and Assistance Level", 
       x = "Score", 
       y = "Group", 
       fill = "Assistance Level") +
  theme(strip.text = element_text(face = "bold"))
