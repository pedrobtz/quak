# Register a Delta, Parquet, CSV, or JSON dataset on a DuckDB connection

Dispatches to
[`load_delta()`](https://pedrobtz.github.io/quak/reference/load_delta.md),
[`load_parquet()`](https://pedrobtz.github.io/quak/reference/load_parquet.md),
[`load_csv()`](https://pedrobtz.github.io/quak/reference/load_csv.md),
or
[`load_json()`](https://pedrobtz.github.io/quak/reference/load_json.md)
based on `format`. Only arguments accepted by the target function may be
passed via `...`; passing `format`-incompatible arguments raises an
error.

## Usage

``` r
load_dataset(
  conn,
  url,
  name,
  format = c("delta", "parquet", "csv", "json"),
  ...
)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL.

- name:

  Character scalar. Name to register the dataset under in DuckDB.

- format:

  One of `"delta"`, `"parquet"`, `"csv"`, or `"json"`.

- ...:

  Passed to the selected loader.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
load_dataset(
  conn,
  "abfss://container@account/path/sales",
  name = "sales",
  format = "delta"
)
} # }
```
