# Collect an Azure-backed lazy tbl as Arrow data

Runs the query behind a table created by
[`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md),
[`tbl_parquet()`](https://pedrobtz.github.io/quak/dev/reference/tbl_parquet.md),
[`tbl_csv()`](https://pedrobtz.github.io/quak/dev/reference/tbl_csv.md)
or
[`tbl_json()`](https://pedrobtz.github.io/quak/dev/reference/tbl_json.md),
reads the whole result into memory, and returns it as an Arrow stream,
without converting it to an R data frame. Runs the same pre-flight
checks as
[`collect.tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/collect.tbl_az.md).

## Usage

``` r
collect_arrow(x)
```

## Arguments

- x:

  A `tbl_az` produced by
  [`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md),
  [`tbl_parquet()`](https://pedrobtz.github.io/quak/dev/reference/tbl_parquet.md),
  [`tbl_csv()`](https://pedrobtz.github.io/quak/dev/reference/tbl_csv.md)
  or
  [`tbl_json()`](https://pedrobtz.github.io/quak/dev/reference/tbl_json.md).

## Value

A `nanoarrow_array_stream` whose batches are already in memory.

## Details

The query has finished when `collect_arrow()` returns, so the connection
is free for other queries. Use
[`stream_arrow()`](https://pedrobtz.github.io/quak/dev/reference/stream_arrow.md)
instead to read a result that is too large to hold in memory.

Requires the nanoarrow package.

## Reading the result

Like any Arrow stream, the result can be read only once. Convert it
straight away, and keep the converted object:

- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) or
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  for an R data frame.

- `arrow::as_arrow_table()` for an Arrow Table, which can be reused.

## Converting the result

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) and
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
convert the result with nanoarrow. The column types mostly match
[`collect.tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/collect.tbl_az.md),
with these exceptions:

- `INTERVAL` columns cannot be converted. Cast them in the query, or
  convert through `arrow::as_arrow_table()`.

- `TIME` columns become `hms` rather than `difftime`.

- `BLOB` columns become `blob` rather than a plain list.

## See also

[`stream_arrow()`](https://pedrobtz.github.io/quak/dev/reference/stream_arrow.md)
to read the result in batches.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
sales <- tbl_delta(conn, "abfss://container@account/path/sales")
tab <- arrow::as_arrow_table(collect_arrow(sales))
} # }
```
