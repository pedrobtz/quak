# Check whether a DuckDB extension is installed

Check whether a DuckDB extension is installed

## Usage

``` r
ext_is_installed(name, conn = conn_default())
```

## Arguments

- name:

  Character scalar. Extension name.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

Logical scalar.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
ext_is_installed("httpfs", conn = conn)
#> [1] FALSE
DBI::dbDisconnect(conn, shutdown = TRUE)
```
