# Uninstall a DuckDB extension

Removes the extension file from DuckDB's `extension_directory`.
Optionally also purges the corresponding entry from the local cache.

## Usage

``` r
ext_uninstall(
  name,
  purge_cache = FALSE,
  cache = ext_cache(),
  conn = conn_default()
)
```

## Arguments

- name:

  Character scalar. Extension name.

- purge_cache:

  Logical. If `TRUE`, also removes the file from `cache`.

- cache:

  An `ext_cache` object. Only used when `purge_cache = TRUE`.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a connection with the extension already installed.
conn <- DBI::dbConnect(duckdb::duckdb())
ext_uninstall("httpfs", conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
} # }
```
