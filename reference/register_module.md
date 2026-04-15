# Register a custom module function

Injects an R function into the clade simulation tick loop at the
specified hook point. The function receives a simplified environment
snapshot (`list(agents, grass, t, specs)`) and must return it (modified
or unmodified). Multiple modules may be registered at the same hook
point; they run in registration order.

## Usage

``` r
register_module(fn, when = "post_tick", name = NULL)
```

## Arguments

- fn:

  A function with signature `function(env) -> env`.

- when:

  Character; one of `"pre_tick"`, `"post_agents"`, `"post_tick"`,
  `"post_reproduce"`. Default `"post_tick"`.

- name:

  Character label for the module (optional; used in
  [`list_modules()`](list_modules.md) output).

## Value

Invisibly `NULL`. Side-effects: adds to the module registry.

## Details

Custom modules can modify:

- `env$agents[[i]]$energy` — agent energy

- `env$agents[[i]]$alive` — set to `FALSE` to kill an agent

- `env$grass` — resource matrix (numeric matrix, rows x cols)

## See also

[`list_modules()`](list_modules.md),
[`clear_modules()`](clear_modules.md), [`run_alife()`](run_alife.md)

## Examples

``` r
# Kill any agent older than 100 ticks
register_module(
  fn   = function(env) {
    for (i in seq_along(env$agents)) {
      if (isTRUE(env$agents[[i]]$age > 100)) env$agents[[i]]$alive <- FALSE
    }
    env
  },
  when = "post_tick",
  name = "max_age_100"
)
clear_modules()
```
