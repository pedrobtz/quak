# Register a JSON dataset as a view on a DuckDB connection

Validates the URL, loads the `azure` extension, then registers the
dataset as a VIEW over `read_json_auto()`. Use
[`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md)
first if the connection needs an Azure secret. Returns `conn` invisibly
— use
[`tbl_json()`](https://pedrobtz.github.io/quak/reference/tbl_json.md) if
you want a
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html).

## Usage

``` r
load_json(conn, url, name, replace = TRUE, ...)
```

## Arguments

- conn:

  A DuckDB connection.

- url:

  Character scalar. Azure Blob URL. Supports glob patterns.

- name:

  Character scalar. Name to register the view under in DuckDB.

- replace:

  Logical. Replace an existing view. Default `TRUE`.

- ...:

  Reader options forwarded to DuckDB's `read_json_auto()`.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
load_json(conn, "abfss://container@account/data/*.json", name = "events")
} # }
```
