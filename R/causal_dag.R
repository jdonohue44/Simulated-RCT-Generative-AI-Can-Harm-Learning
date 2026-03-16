# causal_dag.R — DAG for the cluster-randomized identification strategy

library(ggdag)
library(ggplot2)
library(grid)

plot_causal_dag <- function() {
  dag <- dagify(
    A ~ Z + X_gpa + X_base + D + U,
    Y ~ Z + A + X_gpa + X_base + D + U,
    exposure = "Z",
    outcome  = "Y",
    latent   = "U",
    labels   = c(
      Z      = "Treatment arm\n(classroom-level:\nControl / GPT Base / GPT Tutor)",
      X_gpa  = "Prior GPA\n(pre-treatment)",
      X_base = "Baseline covariates\n(demographics, study hours,\nprivate tutoring, prior ChatGPT use)",
      D      = "Design / scoring factors\n(session, grade,\nteacher, grader)",
      A      = "Assisted practice\nscore",
      Y      = "Unassisted exam score\n(short-term learning proxy)",
      U      = "Unobserved traits\n(motivation, study habits,\nother latent preparedness)"
    ),
    coords = list(
      x = c(
        X_gpa  = 0.0,
        X_base = 0.0,
        D      = 0.0,
        Z      = 1.8,
        U      = 1.8,
        A      = 3.5,
        Y      = 5.4
      ),
      y = c(
        X_gpa  = 1.8,
        X_base = 0.3,
        D      = -1.3,
        Z      = 1.0,
        U      = -2.3,
        A      = 1.0,
        Y      = 1.0
      )
    )
  )

  ggdag(dag, text = FALSE, use_labels = NULL, stylized = FALSE) +
    geom_dag_edges(
      edge_width = 0.7,
      edge_alpha = 0.9,
      arrow_directed = arrow(length = unit(8, "pt"), type = "closed")
    ) +
    geom_dag_point(
      aes(fill = name),
      shape = 21,
      size = 20,
      color = "grey20",
      stroke = 0.6
    ) +
    geom_dag_label_repel(
      aes(label = label),
      size = 3.1,
      seed = 42,
      box.padding = 0.55,
      label.padding = unit(0.18, "lines"),
      fill = "white",
      label.size = 0.2
    ) +
    scale_fill_manual(
      values = c(
        Z      = "#43A047",
        A      = "#1E88E5",
        Y      = "#1565C0",
        X_gpa  = "#FBC02D",
        X_base = "#FFB300",
        D      = "#8E24AA",
        U      = "#BDBDBD"
      )
    ) +
    labs(
      title    = "Causal DAG: Cluster-Randomized Identification",
      subtitle = "Treatment is randomized at the classroom level; assisted practice is a mediator to unassisted exam performance"
    ) +
    theme_dag() +
    coord_equal() +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(size = 10)
    )
}
