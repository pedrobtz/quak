# Preview an Azure dataset

Prints a small preview and invisibly returns it as a tibble-like data
frame.

## Usage

``` r
az_glimpse(conn, url, n = 10, format = NULL)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL.

- n:

  Number of rows to preview. Default `10`.

- format:

  Optional format override. One of `"parquet"`, `"csv"`, `"json"`, or
  `"delta"`. When `NULL`, inferred from `url`.

## Value

Invisibly returns the preview tibble-like data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_glimpse(conn, "abfss://container@account/data/*.parquet", n = 5)
} # }
```
