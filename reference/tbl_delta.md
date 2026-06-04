# Open a Delta Lake table as a lazy dplyr tbl

Validates the URL, loads the `azure` and `delta` extensions, then
returns a lazy
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) over
the table. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs Azure extensions, settings, or secrets.

## Usage

``` r
tbl_delta(
  conn,
  url,
  name = NULL,
  method = c("attach", "view"),
  replace = TRUE,
  version = NULL,
  timestamp = NULL
)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL pointing to a Delta table (e.g.
  `"abfss://container@account.dfs.core.windows.net/path/table"`).

- name:

  Optional character scalar. Name to register the table under in DuckDB.
  When `NULL` (default) the table is scanned directly.

- method:

  `"attach"` (default) or `"view"`. Ignored when `name = NULL`.

- replace:

  Logical. Replace an existing registration of the same name. Default
  `TRUE`. Ignored when `name = NULL`.

- version:

  Optional non-negative Delta table version to read.

- timestamp:

  Optional Delta table timestamp to read. Only one of `version` and
  `timestamp` may be supplied.

## Value

A [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)
backed by the Delta table.

## Details

When `name` is `NULL` the table is queried directly via `delta_scan()`
with no persistent object registered on the connection. When `name` is
supplied the table is first registered via
[`load_delta()`](https://pedrobtz.github.io/quak/reference/load_delta.md)
(as an ATTACH database or a VIEW depending on `method`), then referenced
by name.

Delta time travel currently requires `name` because DuckDB exposes
`version` and `timestamp` through `ATTACH`, not `delta_scan()`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
tbl_delta(conn, "abfss://container@account/path/sales") |>
  dplyr::filter(amount > 100) |>
  dplyr::collect()
} # }
```
