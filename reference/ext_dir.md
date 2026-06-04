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
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

Character scalar. Path to the extension directory.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
ext_dir(conn)
#> [1] "/home/runner/.local/share/R/duckdb/extensions"
DBI::dbDisconnect(conn, shutdown = TRUE)
```
