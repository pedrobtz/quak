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
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

- create:

  Logical. If `TRUE`, create `path` before setting it.

## Value

Invisibly returns the normalized extension directory path.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
ext_set_dir(file.path(tempdir(), "quak-exts"), conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
```
