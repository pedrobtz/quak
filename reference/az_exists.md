# Check whether data exists at an Azure path

For an exact file or glob pattern, checks whether DuckDB's `glob()`
returns at least one match. For a plain path, also probes `url/**` so
dataset prefixes count as existing when they contain at least one
object.

## Usage

``` r
az_exists(conn, url)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL or glob pattern.

## Value

Logical scalar.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_exists(conn, "abfss://container@account/data/sales")
} # }
```
