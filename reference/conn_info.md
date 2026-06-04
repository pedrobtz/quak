# DuckDB instance info

Queries the active connection for the library version and platform
string. The two values together identify the subdirectory path used by
the extension repositories, e.g. `v1.2.0/osx_arm64/`.

## Usage

``` r
conn_info(conn = conn_default())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

A named list with elements `version` (e.g. `"v1.2.0"`) and `platform`
(e.g. `"osx_arm64"`).
