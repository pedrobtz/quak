# Copy data to Azure Data Lake Storage Gen2

Writes a lazy table, data frame, or SQL query to an `abfs://` or
`abfss://` URL using DuckDB's `COPY ... TO` command.

## Usage

``` r
az_copy_to(
  conn,
  x,
  url,
  format = c("parquet", "csv", "json"),
  partition_by = NULL,
  overwrite = FALSE
)
```

## Arguments

- conn:

  A DuckDB connection.

- x:

  A lazy `dbplyr` table, data frame, SQL string, or
  [`DBI::SQL`](https://dbi.r-dbi.org/reference/SQL.html) object.

- url:

  Character scalar. Azure Blob URL to write to.

- format:

  Output format. One of `"parquet"`, `"csv"`, or `"json"`.

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
az_copy_to(
  conn,
  "SELECT * FROM events WHERE event_date >= DATE '2026-01-01'",
  "abfss://container@account/exports/events",
  format = "parquet"
)
} # }
```
