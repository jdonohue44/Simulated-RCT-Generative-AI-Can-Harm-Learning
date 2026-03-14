# causal_dag.R — DAG for the cluster-randomized identification strategy

library(ggdag)
library(ggplot2)

plot_causal_dag <- function() {
  dag <- dagify(
    Y_a ~ Z + X + U,
    Y_u ~ Z + Y_a + X + U,
    exposure = "Z",
    outcome  = "Y_u",
    latent   = "U",
    labels   = c(
      Z   = "Treatment\n(Classroom-level)",
      Y_a = "Assisted\nScore",
      Y_u = "Unassisted\nScore",
      X   = "Prior GPA",
      U   = "Unobserved"
    ),
    coords = list(
      x = c(Z = 0, X = 0, Y_a = 1.5, U = 1.5, Y_u = 3),
      y = c(Z = 0, X = 1.2, Y_a = 0.6, U = -0.6, Y_u = 0)
    )
  )

  ggdag(dag, text = FALSE, use_labels = "label", stylized = FALSE) +
    geom_dag_edges(
      aes(edge_linetype = ifelse(name == "U", "dashed", "solid")),
      edge_width = 0.6,
      arrow_directed = grid::arrow(length = grid::unit(8, "pt"), type = "closed")
    ) +
    geom_dag_point(aes(color = name), size = 22) +
    geom_dag_label_repel(aes(label = label), size = 3.2, seed = 42,
                         box.padding = 0.6) +
    scale_color_manual(
      values = c(
        Z   = "#4CAF50",
        Y_a = "#2196F3",
        Y_u = "#1565C0",
        X   = "#FFC107",
        U   = "#BDBDBD"
      )
    ) +
    labs(
      title    = "Causal DAG: Identification Strategy",
      subtitle = "Random assignment ensures no path from Unobserved to Treatment"
    ) +
    theme_dag() +
    theme(legend.position = "none")
}
