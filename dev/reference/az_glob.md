# List Azure paths matching a glob pattern

Uses DuckDB's `glob()` table function over Azure storage.

## Usage

``` r
az_glob(conn, pattern)
```

## Arguments

- conn:

  A DuckDB connection.

- pattern:

  Character scalar. `abfs://` or `abfss://` glob pattern.

## Value

Character vector of matching paths.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_glob(conn, "abfss://container@account/data/*.parquet")
} # }
```
