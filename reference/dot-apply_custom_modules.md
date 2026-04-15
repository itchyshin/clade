# Apply all registered custom modules at a given hook point

Called by the simulation engine when a hook point is reached. Runs each
registered module in order. Errors are caught and re-raised as warnings
so the simulation continues.

## Usage

``` r
.apply_custom_modules(env_snap, when)
```

## Arguments

- env_snap:

  A list snapshot of the environment.

- when:

  Character; the current hook point.

## Value

The (possibly modified) env snapshot.
