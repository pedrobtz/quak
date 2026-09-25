# Get DuckDB extension repository URLs

Returns the currently active repository URLs. Resolution order per repo:
R option (`quak.core_repo` / `quak.community_repo`) -\> env var
(`QUAK_CORE_REPO` / `QUAK_COMMUNITY_REPO`) -\> built-in default.

## Usage

``` r
repo_urls()
```

## Value

A named list with elements `core` and `community`.

## Examples

``` r
repo_urls()
#> $core
#> [1] "https://extensions.duckdb.org"
#> 
#> $community
#> [1] "https://community-extensions.duckdb.org"
#> 
```
