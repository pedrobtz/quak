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
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with the columns returned by `duckdb_secrets()`.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
az_list_secrets(conn)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: name <chr>, type <chr>, provider <chr>, persistent <lgl>,
#> #   storage <chr>, scope <list>, secret_string <chr>
DBI::dbDisconnect(conn, shutdown = TRUE)
```
