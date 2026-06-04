# Open a CSV dataset as a lazy dplyr tbl

Validates the URL, loads the `azure` extension, then returns a lazy
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) over
the dataset. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs Azure extensions, settings, or secrets.

## Usage

``` r
tbl_csv(conn, url, name = NULL, replace = TRUE, ...)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL. Supports glob patterns.

- name:

  Optional character scalar. Name to register the view under in DuckDB.
  When `NULL` (default) the dataset is scanned directly.

- replace:

  Logical. Replace an existing view of the same name. Default `TRUE`.
  Ignored when `name = NULL`.

- ...:

  Reader options forwarded to DuckDB's `read_csv_auto()`.

## Value

A [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)
backed by the CSV dataset.

## Details

When `name` is `NULL` the dataset is queried directly via
`read_csv_auto()` with no persistent object registered on the
connection. When `name` is supplied the dataset is first registered as a
VIEW via
[`load_csv()`](https://pedrobtz.github.io/quak/reference/load_csv.md),
then referenced by name.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
tbl_csv(conn, "abfss://container@account/data/*.csv") |>
  dplyr::collect()
} # }
```
