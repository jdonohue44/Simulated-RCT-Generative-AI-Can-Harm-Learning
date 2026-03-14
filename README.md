# Simulated RCT: "Generative AI Can Harm Learning"

A simulated randomized control trial replicating the Wharton 2024 study by Bastani et al.

## Key Findings (Simulated)

| Condition  | Assisted effect | Unassisted effect |
|------------|:---------------:|:-----------------:|
| GPT-Base   | +0.137          | **-0.054**        |
| GPT-Tutor  | +0.361          | -0.004            |

GPT-Base boosts short-term performance but **hurts** unassisted performance.
GPT-Tutor improves assisted performance without harming unassisted performance.

## Project Structure

```
├── index.qmd            # Main Quarto report (narrative + analysis calls)
├── R/
│   ├── config.R          # All simulation parameters from the paper
│   ├── simulate.R        # Data generation functions
│   ├── analysis.R        # Regression and t-test functions
│   ├── visualize.R       # Plotting functions
│   ├── power_analysis.R  # MDE calculations for clustered design
│   └── causal_dag.R      # DAG of the identification strategy
├── data/                 # Generated datasets (created on render)
└── .gitignore
```

## How to Run

1. Install R packages:

```r
install.packages(c("here", "truncnorm", "lmtest", "dplyr",
                    "ggplot2", "ggridges", "tidyr", "knitr", "broom"))
```

2. Render the report:

```bash
quarto render index.qmd
```

This generates `index.html` and/or `index.pdf` plus `data/simulated_data.csv`.

## Citation

Bastani, H., Bastani, O., Sungu, A., Ge, H., Kabakcı, Ö., & Mariman, R. (2024).
*Generative AI Can Harm Learning.* The Wharton School Research Paper.
Available at: https://ssrn.com/abstract=4895486
