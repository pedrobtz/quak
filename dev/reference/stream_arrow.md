# Stream an Azure-backed lazy tbl as Arrow record batches

Runs the query behind a table created by
[`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md),
[`tbl_parquet()`](https://pedrobtz.github.io/quak/dev/reference/tbl_parquet.md),
[`tbl_csv()`](https://pedrobtz.github.io/quak/dev/reference/tbl_csv.md)
or
[`tbl_json()`](https://pedrobtz.github.io/quak/dev/reference/tbl_json.md)
and returns a stream that yields the result in batches of at most
`chunk_size` rows. Batches are produced as they are read, so the whole
result never needs to fit in memory. Runs the same pre-flight checks as
[`collect.tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/collect.tbl_az.md).

## Usage

``` r
stream_arrow(x, chunk_size = 1e+06)
```

## Arguments

- x:

  A `tbl_az` produced by
  [`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md),
  [`tbl_parquet()`](https://pedrobtz.github.io/quak/dev/reference/tbl_parquet.md),
  [`tbl_csv()`](https://pedrobtz.github.io/quak/dev/reference/tbl_csv.md)
  or
  [`tbl_json()`](https://pedrobtz.github.io/quak/dev/reference/tbl_json.md).

- chunk_size:

  Positive whole number. The maximum number of rows in each batch.
  DuckDB allocates each batch for `chunk_size` rows up front, so a very
  large value reserves a lot of memory.

## Value

A `nanoarrow_array_stream`.

## Details

Requires the nanoarrow package. Read batches with `stream$get_next()`,
which returns `NULL` once the stream is exhausted, or pass the stream to
`arrow::as_record_batch_reader()`.

## Reading the stream

Read the stream to the end before running any other query on the same
connection. DuckDB ends an open stream as soon as the connection runs
another query, and the stream then reports that it is exhausted without
an error, so the remaining rows are lost silently.

To stop reading early, call `stream$release()`. It frees the query and
its buffers at once, rather than when R next collects garbage.

## See also

[`collect_arrow()`](https://pedrobtz.github.io/quak/dev/reference/collect_arrow.md)
to read the whole result at once.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
sales <- tbl_delta(conn, "abfss://container@account/path/sales")
stream <- stream_arrow(sales, chunk_size = 100000)
while (!is.null(batch <- stream$get_next())) {
  message(batch$length, " rows")
}
} # }
```
