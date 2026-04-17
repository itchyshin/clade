# Remove all registered custom modules

Clears the module registry. Call this after
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
completes if you do not want the modules applied in subsequent runs.

## Usage

``` r
clear_modules()
```

## Value

Invisibly `NULL`.

## See also

[`register_module()`](https://itchyshin.github.io/clade/reference/register_module.md),
[`list_modules()`](https://itchyshin.github.io/clade/reference/list_modules.md)
