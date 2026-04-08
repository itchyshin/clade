# Run this to create placeholder figures for sections 13-22.
# Only creates files that do not already exist.
fig_dir <- system.file("figures", package = "clade")
if (!nzchar(fig_dir)) fig_dir <- file.path("inst", "figures")

placeholders <- c(
  "13_disease", "14_predators", "15_group_defense",
  "16_habitat_preference", "17_seasons", "18_speciation",
  "19_parental_care", "20_cooperative_breeding",
  "21_mimicry", "22_plasticity"
)

labels <- c(
  "13: Disease and Immunity Dynamics",
  "14: Predator-Prey Dynamics",
  "15: Group Defense (Dilution of Risk)",
  "16: Habitat Preference and IFD",
  "17: Seasonal Dynamics",
  "18: Speciation and Genetic Divergence",
  "19: Parental Care and Life History",
  "20: Cooperative Breeding",
  "21: Mimicry and Toxicity",
  "22: Phenotypic Plasticity"
)

for (i in seq_along(placeholders)) {
  nm   <- placeholders[i]
  path <- file.path(fig_dir, paste0("showcase_", nm, ".png"))
  if (!file.exists(path)) {
    png(path, width = 800, height = 500, bg = "white")
    par(mar = c(2, 2, 2, 2))
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
         xlim = c(0, 1), ylim = c(0, 1))
    rect(0, 0, 1, 1, col = "#f5f5f5", border = "grey80", lwd = 2)
    text(0.5, 0.6, paste("Section", labels[i]),
         cex = 1.6, col = "#333333", font = 2)
    text(0.5, 0.4, "[placeholder — run generate_figures.R to build]",
         cex = 1.1, col = "grey50")
    dev.off()
    message("Created: ", path)
  } else {
    message("Exists (skipped): ", path)
  }
}
