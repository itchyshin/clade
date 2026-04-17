# Load simulation specs from a JSON file

Reads a JSON file containing simulation parameters and merges it over
the defaults from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
Parameters not present in the JSON file retain their defaults;
parameters in the JSON that are not valid spec names trigger a warning.

## Usage

``` r
load_specs(path)
```

## Arguments

- path:

  Character. Path to a JSON file. The file should contain a single JSON
  object whose keys are parameter names from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
  Numeric vectors of length 1 are read as scalars; longer vectors as R
  vectors.

## Value

A specs list (same format as
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)).

## Details

Load simulation specs from a JSON file

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# specs.json contains {"mutation_sd": 0.3, "grass_rate": 0.6}
specs <- load_specs("path/to/specs.json")
env   <- run_alife(specs)
} # }
```
