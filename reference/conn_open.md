# Create a DuckDB connection

Thin wrapper around
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
with quak-friendly defaults.

## Usage

``` r
conn_open(..., drv = conn_driver(), timezone_out = "", array = "matrix")
```

## Arguments

- ...:

  Additional arguments passed to
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- drv:

  A DuckDB driver. Defaults to
  [`conn_driver()`](https://pedrobtz.github.io/quak/reference/conn_driver.md).

- timezone_out:

  Character scalar. Timezone for `TIMESTAMPTZ` output. Defaults to `""`
  (UTC).

- array:

  Character scalar. How to represent DuckDB arrays. Defaults to
  `"matrix"`.

## Value

A `duckdb_connection` object.
