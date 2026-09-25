# List installed DuckDB extensions

Queries `duckdb_extensions()`, returning only extensions where
`installed = TRUE`.

## Usage

``` r
ext_list_installed(conn = conn_default())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns: `name`, `installed`, `loaded`, `version`, `description`.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpcx2puQ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
ext_list_installed(conn)
#> # A tibble: 2 × 5
#>   name           installed loaded version description                           
#>   <chr>          <lgl>     <lgl>  <chr>   <chr>                                 
#> 1 core_functions TRUE      TRUE   ""      Core function library                 
#> 2 parquet        TRUE      TRUE   ""      Adds support for reading and writing …
DBI::dbDisconnect(conn, shutdown = TRUE)
```
