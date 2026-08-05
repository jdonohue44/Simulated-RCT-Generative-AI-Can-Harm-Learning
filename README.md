# Generative AI and Learning: RCT Simulation & Replication

## What is this Project?

This project has two parts.

First, it simulates the RCT design from Bastani et al. (2025), which found that high school students given unrestricted GPT-4 access while solving practice math problems scored worse on a later, unassisted exam than students who never had access. A safeguarded "GPT Tutor" variant, prompted to give hints instead of final answers, largely avoided this harm. The simulation generates synthetic student-level data matching the paper's three-arm design (control, GPT Base, GPT Tutor), so the identification strategy, power analysis, and covariate balance diagnostics can be explored and taught without touching real student records.

Second, it reproduces the paper's main regression, balance, and moderator results directly from the author-shared dataset, to validate the simulation against ground truth and to support further exploration of the real data.

## The Paper

```bibtex
@article{bastani2025generative,
  title={Generative AI without guardrails can harm learning: Evidence from high school mathematics},
  author={Bastani, Hamsa and Bastani, Osbert and Sungu, Alp and Ge, Haosen and Kabakc{\i}, {\"O}zge and Mariman, Rei},
  journal={Proceedings of the National Academy of Sciences},
  volume={122},
  number={26},
  pages={e2422633122},
  year={2025},
  doi={10.1073/pnas.2422633122}
}
```

**Author-shared data and code:** [github.com/obastani/GenAICanHarmLearning](https://github.com/obastani/GenAICanHarmLearning)

## Project Structure

```
├── index.qmd                     # Main Quarto report (narrative + analysis)
├── R/
   ├── config.R                   # Simulation parameters
   ├── simulate.R                 # Data generation
   ├── analysis.R                 # Regression and t-test functions
   ├── visualize.R                # Plotting functions
   ├── power_analysis.R           # MDE calculations
   ├── causal_dag.R               # Causal DAG visualization
   ├── real_data_analysis.R       # Reproduces main regression, balance, moderator (original)
   ├── main_analysis.R            # Author's main regression script (verbatim copy, see header)
   └── problem_level_analysis.R   # Author's problem-level script (verbatim copy, see header)
├── data/
   ├── simulated_data.csv         # Simulated data
   ├── final_data.csv             # Author-shared data CSV
   ├── final_data.sqlite          # Author-shared data SQLite
   ├── final_data_spot_check.sql  # SQL queries for spot-checking and describing author-shared final data
└── outputs/
   ├── figures/                   # coefficient_plot_main.png, love_plot_balance.png
   └── tables/                    # main_regression_coefficients.csv, etc.
└── .gitignore
```

## How to Run and Generate the Quarto Report

Requires R and the [Quarto CLI](https://quarto.org/docs/get-started/) installed locally.

1. Install R packages:

```r
install.packages(c("here", "truncnorm", "lmtest", "sandwich", "dplyr",
                    "ggplot2", "ggridges", "tidyr", "knitr", "broom",
                    "ggdag"))
```

2. Render the report:

```bash
quarto render index.qmd
```

This generates `index.html` and/or `index.pdf` plus `data/simulated_data.csv`.

## Extending the Analysis using Author-shared Data

The tables below describe the full author-shared dataset from the upstream [GenAICanHarmLearning](https://github.com/obastani/GenAICanHarmLearning) repo. This project currently vendors `final_data.csv` (and derived `final_data.sqlite`) under `data/`. The other files and folders below live in the upstream repo only; they're documented here as a reference for anyone extending `main_analysis.R` or `problem_level_analysis.R`, or adding new analyses.

### Author-shared Data includes:

1. `main_regressions/` - Contains R scripts and some additional data files needed for the main analyses in the paper and some robustness checks.
2. `additional_results/` - Contains Python and Stata scripts and some additional data files needed for analyses related to covariate balance, student perception, heterogeneous treatment effects, student performance dispersion, and student absenteeism.
3. `text_analysis/` - Contains scripts and data files needed for the analysis of student messages and GPT error rates, plus its own readme.md file.
4. `final_data.csv` - Contains the main dataset generated from the study.

### Data Dictionary

##### `final_data.csv`, `main_regressions/problem_part3.csv`, `main_regressions/problem_part2.csv`, and `additional_results/final_data.csv`

| Column                                           | Description                                                                           |
| ------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `Student ID`                                     | Unique identifier for each student                                                    |
| `Class`                                          | Class identifier                                                                      |
| `Year`                                           | Academic year                                                                         |
| `Session`                                        | The experiment session identifier                                                     |
| `Grader`                                         | Grader identifier                                                                     |
| `Part2Tot`                                       | Part 2 student score                                                                  |
| `Part3Tot`                                       | Part 3 student score                                                                  |
| `Survey Q1`–`Survey Q5`                          | Responses to survey questions                                                         |
| `gpa_prev`                                       | Previous GPA of the student                                                           |
| `GPTBase`, `GPTTutor`                            | Indicators for treatment assignment                                                   |
| `teacher`                                        | Teacher identifier                                                                    |
| `n_household_members`                            | Number of members in the household                                                    |
| `class_enjoyment`                                | Self-reported student sentiment                                                       |
| `class_participation_likelihood`                 | Self-reported student participation                                                   |
| `n_weekday_study_hours`, `n_weekend_study_hours` | Self-reported study hours on weekdays and weekends                                    |
| `math_hw_completion`                             | Homework completion                                                                   |
| `hw_help`                                        | Indicator of whether the student receives help for homework                           |
| `private_tutorship`, `visit_training_center`     | Indicator of whether the student receives private tutorship or visits training center |
| `chatgpt_use`                                    | Self-reported indicator of whether the student has previous experience with ChatGPT   |
| `Treatment arm`                                  | Treatment assignment                                                                  |
| `female`                                         | Gender indicator                                                                      |
| `education_parent`                               | Parental education                                                                    |
| `n_household_children`                           | Number of children in household                                                       |
| `Honors`                                         | Honors class participation indicator                                                  |

##### `main_regressions/problem_mapping.csv`

| Column         | Description                            |
| -------------- | -------------------------------------- |
| `part2, part3` | Mappings of Part 2 and Part 3 problems |

##### `main_regressions/gpt_answers_full.csv`

| Column              | Description                                           |
| ------------------- | ----------------------------------------------------- |
| `problem`           | Problem identifier                                    |
| `0–9`               | Ten GPT responses to the same problem                 |
| `g0–g9`             | Correctness labels of the corresponding GPT responses |
| `total_correct`     | Number of correct answers                             |
| `logical_errors`    | Number of answers that make logic errors              |
| `arithmetic_errors` | Number of answers that make arithmetic errors         |

##### `text_analysis/data/raw/valid_student_data.csv` and `text_analysis/data/raw/valid_student_data_w_time_stamp.csv`

| Column            | Description                                 |
| ----------------- | -------------------------------------------- |
| `role`            | Role of the message sender (student or GPT) |
| `message`         | Actual message content                      |
| `conversation_id` | Unique identifier for conversation          |
| `username`        | Student identifier                          |
| `grade`           | Grade                                       |
| `problem_id`      | Problem identifier                          |
| `session_id`      | Experiment session identifier               |
| `time_stamp`      | Timestamp of the message                    |
| `treatment`       | Treatment assignment                        |

##### `text_analysis/data/raw/question_list.csv`

| Column       | Description        |
| ------------ | ------------------ |
| `session`    | Experiment session |
| `grade`      | Grade              |
| `problem_id` | Problem identifier |
| `question`   | Problem text       |
| `answers`    | Empty              |

##### `additional_results/df_attendance.dta`

| Column                           | Description                                         |
| --------------------------------- | ---------------------------------------------------- |
| `Student_ID`                     | Unique identifier for each student                  |
| `Session`                        | Experiment session                                  |
| `Class`                          | Class                                               |
| `Year`                           | Academic year                                       |
| `Grader`                         | Grader identifier                                   |
| `Part2Tot`                       | Part 2 score                                        |
| `Part3Tot`                       | Part 3 score                                        |
| `Survey_Q1` to `Survey_Q5`       | Survey responses (Q1–Q5)                            |
| `gpa_prev`                       | Previous GPA                                        |
| `GPTBase`, `GPTTutor`            | Treatment assignment                                |
| `teacher`                        | Teacher identifier                                  |
| `n_household_members`            | Number of household members                         |
| `class_enjoyment`                | Self-reported class enjoyment                       |
| `class_participation_likelihood` | Self-reported class participation                   |
| `n_weekday_study_hours`          | Weekday study hours                                 |
| `n_weekend_study_hours`          | Weekend study hours                                 |
| `math_hw_completion`             | Math homework completion indicator                  |
| `hw_help`                        | Help with homework indicator                        |
| `private_tutorship`              | Private tutoring indicator                          |
| `visit_training_center`          | Visits to training center indicator                 |
| `chatgpt_use`                    | Indicator of previous use of ChatGPT                |
| `Treatment_arm`                  | Treatment assignment, same as `GPTBase`, `GPTTutor` |
| `female`                         | Gender indicator                                    |
| `education_parent`               | Parent education level                              |
| `n_household_children`           | Number of children in household                     |
| `Honors`                         | Honors student indicator                            |
| `Attendance`                     | Attendance record                                   |
| `Session_class`                  | Combined session-class identifier                   |

##### `additional_results/df_class.dta`

| Column     | Description                |
| ---------- | --------------------------- |
| `Class`    | Class identifier           |
| `Session`  | Session number              |
| `Part2Tot` | Average Part 2 total score |
| `Part3Tot` | Average Part 3 total score |
| `GPTBase`  | Average GPT base score     |
| `GPTTutor` | Average GPT tutor score    |
| `gpa_prev` | Average previous GPA       |
| `teacher`  | Teacher identifier         |
| `Grader`   | Grader identifier          |
| `Year`     | Academic year               |

##### `additional_results/df_perception.dta`

| Column                           | Description                                             |
| --------------------------------- | --------------------------------------------------------- |
| `Student_ID`                     | Unique identifier for each student                      |
| `Class`                          | Class identifier                                        |
| `Year`                           | Academic year                                           |
| `Session`                        | Experiment session                                      |
| `Grader`                         | Grader identifier                                        |
| `Part2Tot`                       | Part 2 score                                            |
| `Part3Tot`                       | Part 3 score                                            |
| `perceived_learning`             | Student's perceived learning                            |
| `perceived_performance`          | Student's perceived performance                         |
| `exam_duration`                  | Total exam duration                                     |
| `perceived_value_practise`       | Perceived value of the practice                         |
| `time_tradeoff`                  | Time trade-off                                           |
| `gpa_prev`                       | Previous GPA                                             |
| `GPTBase`, `GPTTutor`            | Treatment assignment                                     |
| `teacher`                        | Teacher identifier                                        |
| `n_household_members`            | Number of household members                              |
| `class_enjoyment`                | Self-reported class enjoyment level                       |
| `class_participation_likelihood` | Self-reported class participation                        |
| `n_weekday_study_hours`          | Weekday study hours                                       |
| `n_weekend_study_hours`          | Weekend study hours                                       |
| `math_hw_completion`             | Math homework completion                                  |
| `hw_help`                        | Help with homework indicator                              |
| `private_tutorship`              | Private tutoring indicator                                 |
| `visit_training_center`          | Visits to training center indicator                       |
| `chatgpt_use`                    | Indicator of previous ChatGPT use                          |
| `Treatment_arm`                  | Treatment assignment. The same as `GPTBase`, `GPTTutor`   |
| `female`                         | Gender indicator                                           |
| `education_parent`               | Parent education level                                     |
| `n_household_children`           | Number of children in household                            |
| `Honors`                         | Honors student indicator                                   |

## Attribution

This project builds on data and code shared by the paper's authors. If you use or extend it, cite the original paper (see [The Paper](#the-paper) above) and the [author-shared repository](https://github.com/obastani/GenAICanHarmLearning).
