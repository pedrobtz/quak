# Collect an Azure-backed lazy tbl

[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
method for tables created by
[`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md)
and
[`tbl_parquet()`](https://pedrobtz.github.io/quak/reference/tbl_parquet.md).
Verifies that the backing DuckDB connection is still open and that the
`azure` extension is loaded before the query is materialised, then
defers to the underlying dbplyr method.

## Usage

``` r
# S3 method for class 'tbl_az'
collect(x, ...)
```

## Arguments

- x:

  A `tbl_az` produced by
  [`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md)
  or
  [`tbl_parquet()`](https://pedrobtz.github.io/quak/reference/tbl_parquet.md).

- ...:

  Passed on to the next `collect()` method.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with the collected rows.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
tbl_delta(conn, "abfss://container@account/path/sales") |>
  dplyr::collect()
} # }
```
