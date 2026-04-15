# Getting Started with clade

`clade` is an agent-based evolutionary simulator. Digital organisms
carry heritable neural-network genomes and forage on a renewable
resource grid. Natural selection acts on brain weights, life-history
traits, and — with optional modules — body size, dispersal tendency,
wing morphology, helper behaviour, and more.

The simulation runs entirely in Julia (via
[JuliaConnectoR](https://cran.r-project.org/package=JuliaConnectoR)), so
the R session only crosses the R–Julia boundary once per call:
[`run_alife()`](../reference/run_alife.md) sends specs in and receives
the full environment back.

------------------------------------------------------------------------

## 1. Installation

### R package

``` r
# From GitHub (development version)
remotes::install_github("itchyshin/clade")

# Or from CRAN when released
# install.packages("clade")
```

### Julia

clade requires Julia \>= 1.9. Download it from
[julialang.org](https://julialang.org/downloads/) or use
[juliaup](https://github.com/JuliaLang/juliaup):

``` bash
curl -fsSL https://install.julialang.org | sh
```

On the **first** call to [`run_alife()`](../reference/run_alife.md),
Julia compiles the simulation kernel. This takes 60–90 seconds and is
cached for all subsequent runs in the same Julia environment.

------------------------------------------------------------------------

## 2. Check that Julia is ready

``` r
library(clade)

if (!julia_is_ready()) {
  stop("Julia not found. See ?julia_is_ready for setup instructions.")
}
cat("Julia", julia_version(), "ready.\n")
```

If Julia is not found, the most common fixes are:

- Add Julia to `PATH` (run `export PATH="$PATH:~/.juliaup/bin"` in your
  shell).
- Set `JULIA_BINDIR` in your `.Renviron` file.
- Reinstall Julia via `juliaup`.

------------------------------------------------------------------------

## 3. Your first run

[`default_specs()`](../reference/default_specs.md) returns the full
parameter list with sensible defaults. Modify only what you need, then
pass to [`run_alife()`](../reference/run_alife.md).

``` r
library(clade)

specs <- default_specs()
specs$grid_rows     <- 20L
specs$grid_cols     <- 20L
specs$n_agents_init <- 40L
specs$max_ticks     <- 200L
specs$random_seed   <- 1L

env <- run_alife(specs)

# S3 print: one-line summary
print(env)
```

    #> clade_env  [200 ticks | 47 agents | genetic_diversity: 0.312]

`env` is a `clade_env` object. Its key fields are:

| Field          | Contents                                      |
|----------------|-----------------------------------------------|
| `env$agents`   | List of surviving agents (one list per agent) |
| `env$progress` | Data frame of per-tick population statistics  |
| `env$deaths`   | Data frame of per-death records               |
| `env$specs`    | The specs list used for this run              |
| `env$grass`    | Final grass coverage matrix                   |

------------------------------------------------------------------------

## 4. Extracting and plotting results

``` r
data <- get_run_data(env)

# data$ticks  — per-tick population statistics
# data$deaths — one row per agent death

plot_run(data)   # multi-panel dashboard: population, energy, diversity
```

![plot_run() produces a six-panel dashboard: population size, mean
energy (±SD ribbon), genetic diversity, births and deaths per tick,
grass coverage, and BNN prior
sigma.](figures/showcase_01_run_dashboard.png)

plot_run() produces a six-panel dashboard: population size, mean energy
(±SD ribbon), genetic diversity, births and deaths per tick, grass
coverage, and BNN prior sigma.

`data$ticks` contains columns including `t`, `n_agents`, `mean_energy`,
`genetic_diversity`, `n_births`, `n_deaths`, and columns for every
active module (e.g. `mean_wing_size` when `complex_landscape = TRUE`).

------------------------------------------------------------------------

## 5. Inspecting parameters

[`print_specs()`](../reference/print_specs.md) prints every parameter
grouped by biological theme. Use `diff_only = TRUE` to show only what
you changed:

``` r
specs2 <- default_specs()
specs2$kin_selection    <- TRUE
specs2$complex_landscape <- TRUE
specs2$max_ticks        <- 400L

print_specs(specs2, diff_only = TRUE)
```

    #> -- clade specs (88 parameters) [diff only] --
    #>
    #>   Grid & population
    #>     max_ticks                              400 *
    #>
    #>   Kin selection
    #>     kin_selection                         TRUE *
    #>
    #>   Complex landscape
    #>     complex_landscape                     TRUE *

------------------------------------------------------------------------

## 6. Key parameters at a glance

| Parameter             | Default | Role                                                          |
|:----------------------|:--------|:--------------------------------------------------------------|
| grid_rows / grid_cols | 20 x 20 | World size                                                    |
| n_agents_init         | 50      | Starting population                                           |
| max_agents            | 300     | Population cap                                                |
| max_ticks             | 300     | Simulation length                                             |
| random_seed           | 42      | Reproducibility                                               |
| brain_type            | “bnn”   | Neural architecture (bnn/ann/ctrnn/grn/transformer/synthesis) |
| ploidy                | 2       | Haploid (1) or diploid (2)                                    |
| grass_rate            | 0.10    | Grass regrowth probability per tick                           |
| mutation_sd           | 0.05    | Genome mutation rate                                          |
| kin_selection         | FALSE   | Enable kin altruism                                           |
| disease               | FALSE   | Enable SIR disease                                            |
| complex_landscape     | FALSE   | Enable 3-layer habitat                                        |
| dispersal_evolution   | FALSE   | Allow dispersal to evolve                                     |
| spatial_sorting       | FALSE   | Enable invasion-front assortment                              |
| iffolk_selection      | FALSE   | Enable inclusive fitness transfers                            |
| cooperative_breeding  | FALSE   | Enable alloparental helpers                                   |
| body_size_evolution   | FALSE   | Enable body-size scaling                                      |
| niche_construction    | FALSE   | Enable shelter building                                       |
| social_learning       | FALSE   | Enable copying neighbours’ brain weights                      |
| parental_care         | FALSE   | Enable offspring carried until graduation                     |

Selected [`default_specs()`](../reference/default_specs.md) parameters.

------------------------------------------------------------------------

## 7. Running multiple scenarios in parallel

[`batch_alife()`](../reference/batch_alife.md) runs a list of specs
across R worker processes:

``` r
specs_list <- lapply(c(0.05, 0.10, 0.20), function(gr) {
  s <- default_specs()
  s$grass_rate <- gr
  s$max_ticks  <- 200L
  s
})

results <- batch_alife(specs_list, n_cores = 3L)

# Compare mean genetic diversity across grass rates
sapply(results, function(env) {
  mean(get_run_data(env)$ticks$genetic_diversity, na.rm = TRUE)
})
```

------------------------------------------------------------------------

## 8. Next steps

- **Biological scenarios**: see
  [`vignette("scenarios")`](../articles/scenarios.md) for a tour of all
  modules with code and expected outputs.
- **Parameter search**: see
  [`vignette("diversity-search")`](../articles/diversity-search.md) for
  CMA-ES, MAP-Elites, and the viability mapping workflow.
- **Auto-calibration** (0.3.0): each scenario has a per-vignette CMA-ES
  harness at `dev/audit/calibration/` that discovers the regime where
  its claimed biology emerges. Run with
  `bash dev/audit/calibration/run_all.sh`; results in
  `dev/audit/calibration/RESULTS.md`.
- **Custom modules**: see
  [`vignette("custom-modules")`](../articles/custom-modules.md) to write
  your own per-tick hooks.
- **Audit harness** (0.3.0): `dev/audit/run_audit.R` runs all 35
  vignette scenarios against the live kernel and confirms each produces
  the signal its “What we found” prose claims.
