# Get Azure settings from a DuckDB connection

Queries `duckdb_settings()` and returns all entries whose name contains
`"azure"`.

## Usage

``` r
az_conn_settings(conn = az_conn())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `name`, `value`, `description`.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
az_conn_settings(conn)
#> # A tibble: 0 × 3
#> # ℹ 3 variables: name <chr>, value <chr>, description <chr>
DBI::dbDisconnect(conn, shutdown = TRUE)
```
