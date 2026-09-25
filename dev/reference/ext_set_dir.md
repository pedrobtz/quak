# Set the DuckDB extension folder

Changes the path where DuckDB stores installed extension files for
`conn`. The value is written to DuckDB's `extension_directory` setting.

## Usage

``` r
ext_set_dir(path, conn = conn_default(), create = TRUE)
```

## Arguments

- path:

  Character scalar. Path to the extension directory.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

- create:

  Logical. If `TRUE`, create `path` before setting it.

## Value

Invisibly returns the normalized extension directory path.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpVpZTOE/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
ext_set_dir(file.path(tempdir(), "quak-exts"), conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
```
