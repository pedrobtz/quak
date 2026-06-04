# Write Parquet data to Azure Data Lake Storage Gen2

Thin convenience wrapper around
[`az_copy_to()`](https://pedrobtz.github.io/quak/reference/az_copy_to.md)
with `format = "parquet"`.

## Usage

``` r
az_write_parquet(conn, x, url, partition_by = NULL, overwrite = FALSE)
```

## Arguments

- conn:

  A DuckDB connection.

- x:

  A lazy `dbplyr` table, data frame, SQL string, or
  [`DBI::SQL`](https://dbi.r-dbi.org/reference/SQL.html) object.

- url:

  Character scalar. Azure Blob URL to write to.

- partition_by:

  Optional character vector of columns to partition by.

- overwrite:

  Logical. When `TRUE`, passes DuckDB's `OVERWRITE_OR_IGNORE` copy
  option.

## Value

Invisibly returns `url`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_write_parquet(conn, data.frame(x = 1:3), "abfss://container@account/x")
} # }
```
