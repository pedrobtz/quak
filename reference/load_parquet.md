# Register a Parquet dataset as a view on a DuckDB connection

Validates the URL, loads the `azure` extension, then registers the
dataset as a VIEW. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs an Azure secret. Returns `conn` invisibly
— use
[`tbl_parquet()`](https://pedrobtz.github.io/quak/reference/tbl_parquet.md)
if you want a
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html).

## Usage

``` r
load_parquet(conn, url, name, hive_partitioning = FALSE, replace = TRUE)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL. Supports glob patterns.

- name:

  Character scalar. Name to register the view under in DuckDB.

- hive_partitioning:

  Logical. Enable Hive partition inference. Default `FALSE`.

- replace:

  Logical. Replace an existing view. Default `TRUE`.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
load_parquet(conn, "abfss://container@account/data/*.parquet", name = "events")
} # }
```
