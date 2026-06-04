# Register a Delta Lake table on a DuckDB connection

Validates the URL, loads the `azure` and `delta` extensions, then
registers the table either as an ATTACH database or a VIEW. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs an Azure secret. Returns `conn` invisibly
— use
[`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md)
if you want a
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html).

## Usage

``` r
load_delta(
  conn,
  url,
  name,
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

  Character scalar. Azure Blob URL pointing to a Delta table.

- name:

  Character scalar. Name to register the table under in DuckDB.

- method:

  `"attach"` (default) or `"view"`.

- replace:

  Logical. Replace an existing registration. Default `TRUE`.

- version:

  Optional non-negative Delta table version to attach.

- timestamp:

  Optional Delta table timestamp to attach. Only one of `version` and
  `timestamp` may be supplied.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
load_delta(conn, "abfss://container@account/path/sales", name = "sales")
DBI::dbGetQuery(conn, "SELECT COUNT(*) FROM sales")
} # }
```
