# Find the DuckDB extension folder

Returns the path where DuckDB stores installed extension files. This is
determined by the `extension_directory` setting.

## Usage

``` r
ext_dir(conn = conn_default())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

## Value

Character scalar. Path to the extension directory.

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
ext_dir(conn)
#> [1] "/tmp/Rtmpcx2puQ/duckdb/extensions"
DBI::dbDisconnect(conn, shutdown = TRUE)
```
