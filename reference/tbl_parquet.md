# Open a Parquet dataset as a lazy dplyr tbl

Validates the URL, loads the `azure` extension, then returns a lazy
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) over
the dataset. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs Azure extensions, settings, or secrets.

## Usage

``` r
tbl_parquet(conn, url, name = NULL, hive_partitioning = FALSE, replace = TRUE)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL. Supports glob patterns for
  multi-file datasets (e.g.
  `"abfss://container@account.dfs.core.windows.net/data/*.parquet"`).

- name:

  Optional character scalar. Name to register the view under in DuckDB.
  When `NULL` (default) the dataset is scanned directly.

- hive_partitioning:

  Logical. Enable Hive partition inference from the directory structure.
  Default `FALSE`.

- replace:

  Logical. Replace an existing view of the same name. Default `TRUE`.
  Ignored when `name = NULL`.

## Value

A [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)
backed by the Parquet dataset.

## Details

When `name` is `NULL` the dataset is queried directly via
`read_parquet()` with no persistent object registered on the connection.
When `name` is supplied the dataset is first registered as a VIEW via
[`load_parquet()`](https://pedrobtz.github.io/quak/reference/load_parquet.md),
then referenced by name. Glob patterns (e.g. `"*.parquet"`) are
supported in `url` for multi-file datasets.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
tbl_parquet(conn, "abfss://container@account/data/*.parquet") |>
  dplyr::collect()
} # }
```
