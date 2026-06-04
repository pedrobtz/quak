# Install a DuckDB extension from a local file

Executes `INSTALL '/path/to/ext.duckdb_extension'` on `conn`. Use this
to install an extension binary you already have on disk without going
through a remote repository.

## Usage

``` r
ext_install_local(path, name = NULL, conn = conn_default())
```

## Arguments

- path:

  Character scalar. Path to the `.duckdb_extension` file.

- name:

  Character scalar. Extension name used in messages. Inferred from
  `path` when omitted.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a local DuckDB extension file at the given path.
conn <- DBI::dbConnect(duckdb::duckdb())
ext_install_local("/path/to/httpfs.duckdb_extension", conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
} # }
```
