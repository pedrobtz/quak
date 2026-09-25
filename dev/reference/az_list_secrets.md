# List Azure secrets registered in DuckDB

Queries `duckdb_secrets()` and returns secrets whose `type` is
`"azure"`. Values are returned as DuckDB reports them; DuckDB handles
redaction of sensitive fields.

## Usage

``` r
az_list_secrets(conn = conn_default())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with the columns returned by `duckdb_secrets()`.

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
az_list_secrets(conn)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: name <chr>, type <chr>, provider <chr>, persistent <lgl>,
#> #   storage <chr>, scope <list>, secret_string <chr>
DBI::dbDisconnect(conn, shutdown = TRUE)
```
