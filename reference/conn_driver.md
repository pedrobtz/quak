# Create a DuckDB driver

Thin wrapper around
[`duckdb::duckdb()`](https://r.duckdb.org/reference/duckdb.html) with
quak-friendly defaults.

## Usage

``` r
conn_driver(
  dbdir = ":memory:",
  read_only = FALSE,
  bigint = "numeric",
  config = list(),
  ...,
  unsigned = FALSE,
  environment_scan = FALSE
)
```

## Arguments

- dbdir:

  Character scalar. Database path. Defaults to `":memory:"`.

- read_only:

  Logical. Open in read-only mode. Defaults to `FALSE`.

- bigint:

  Character scalar. How to represent 64-bit integers. Defaults to
  `"numeric"`.

- config:

  Named list of DuckDB configuration options. Defaults to
  [`list()`](https://rdrr.io/r/base/list.html).

- ...:

  Additional arguments passed to
  [`duckdb::duckdb()`](https://r.duckdb.org/reference/duckdb.html).

- unsigned:

  Logical. Allow loading unsigned (locally-built or community)
  extensions — equivalent to `duckdb -unsigned` on the CLI. Sets
  `allow_unsigned_extensions = "true"` in `config`. Defaults to `FALSE`.

- environment_scan:

  Logical. Scan the R environment for secrets. Defaults to `FALSE`.

## Value

A `duckdb_driver` object.
