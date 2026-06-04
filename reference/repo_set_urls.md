# Set DuckDB extension repository URLs

Stores URLs in R options `quak.core_repo` / `quak.community_repo` so
they can be configured org-wide in `.Rprofile`. When `core` is supplied,
also sets DuckDB's `custom_extension_repository` on `conn`; passing
`NULL` resets that connection setting to DuckDB's default.

## Usage

``` r
repo_set_urls(
  core = NULL,
  community = NULL,
  check = TRUE,
  conn = conn_default()
)
```

## Arguments

- core:

  Optional character scalar. URL for the core extension repository. Omit
  to leave the current value unchanged. Pass `NULL` to reset to the
  DuckDB default.

- community:

  Optional character scalar. URL for the community extension repository.
  Omit to leave the current value unchanged. Pass `NULL` to reset to the
  DuckDB default.

- check:

  Logical. If `TRUE` (default), calls
  [`repo_check()`](https://pedrobtz.github.io/quak/reference/repo_check.md)
  for each repository whose URL was changed, probing `"httpfs"` as a
  baseline extension.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).
  Used to set `custom_extension_repository` when `core` is supplied, and
  by
  [`repo_check()`](https://pedrobtz.github.io/quak/reference/repo_check.md)
  when `check = TRUE`.

## Value

Invisibly returns a named list with elements `core` and `community`
reflecting the current option values.

## Examples

``` r
old <- repo_urls()
repo_set_urls(core = "https://extensions.example.com", check = FALSE)
#> ✔ Set `custom_extension_repository` = "https://extensions.example.com"
repo_urls()
#> $core
#> [1] "https://extensions.example.com"
#> 
#> $community
#> [1] "https://community-extensions.duckdb.org"
#> 
repo_set_urls(core = old$core, check = FALSE)
#> ✔ Set `custom_extension_repository` = "https://extensions.duckdb.org"
```
