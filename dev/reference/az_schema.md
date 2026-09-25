# Inspect a dataset schema without collecting data

Uses DuckDB's `DESCRIBE SELECT` over a remote scan and returns only
column names and DuckDB types.

## Usage

``` r
az_schema(conn, url, format = NULL)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL.

- format:

  Optional format override. One of `"parquet"`, `"csv"`, `"json"`, or
  `"delta"`. When `NULL`, inferred from `url`.

## Value

A tibble-like data frame with columns `name` and `type`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_schema(conn, "abfss://container@account/data/*.parquet")
} # }
```
