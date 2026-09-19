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
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpfq6aqc/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
az_conn_settings(conn)
#> # A tibble: 0 × 3
#> # ℹ 3 variables: name <chr>, value <chr>, description <chr>
DBI::dbDisconnect(conn, shutdown = TRUE)
```
