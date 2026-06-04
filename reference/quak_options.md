# List all quak options and their current values

Prints every quak option (via
[`print.quak_opts()`](https://pedrobtz.github.io/quak/reference/print.quak_opts.md))
and invisibly returns a tibble of the same information. The resolution
order is: value set via `options(quak.*)` -\> the option's env var -\> a
built-in default.

## Usage

``` r
quak_options(mask = TRUE)
```

## Arguments

- mask:

  Logical. When `TRUE` (default), sensitive option values are shown as
  `"<hidden>"` when set.

## Value

Invisibly, a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `option`, `value`, `source`, `env_var`, `env_value`, and
`default`.

## Examples

``` r
quak_options()
#> 
#> ── quak options ────────────────────────────────────────────────────────────────
#> cache_dir = "/home/runner/.cache/R/quak" (default)
#>   `QUAK_CACHE_DIR`: (not set)
#> collect_verbose = "TRUE" (default)
#>   `QUAK_COLLECT_VERBOSE`: (not set)
#> community_repo = "https://community-extensions.duckdb.org" (default)
#>   `QUAK_COMMUNITY_REPO`: (not set)
#> core_repo = "https://extensions.duckdb.org" (default)
#>   `QUAK_CORE_REPO`: (not set)
#> default_exts = "httpfs, azure, delta" (default)
#>   `QUAK_DEFAULT_EXTS`: (not set)
#> default_scope = "https://storage.azure.com/.default" (default)
#>   `QUAK_DEFAULT_SCOPE`: (not set)
#> install_verbose = "TRUE" (default)
#>   `QUAK_INSTALL_VERBOSE`: (not set)
#> startup_repo_check = "TRUE" (default)
#>   `QUAK_STARTUP_REPO_CHECK`: (not set)
```
