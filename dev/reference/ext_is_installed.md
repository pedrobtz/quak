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
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

## Value

Logical scalar.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp3eHl3G/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
ext_is_installed("httpfs", conn = conn)
#> [1] FALSE
DBI::dbDisconnect(conn, shutdown = TRUE)
```
