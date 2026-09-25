# List files in a Delta table on Azure Data Lake Storage Gen2

Returns DuckDB's `delta_list_files()` output for a Delta table.

## Usage

``` r
az_delta_files(conn, url)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL pointing to a Delta table.

## Value

A tibble-like data frame with the active file manifest.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_delta_files(conn, "abfss://container@account/tables/sales")
} # }
```
