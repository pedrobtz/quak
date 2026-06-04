# Get or set DuckDB settings

When called with no arguments, returns all settings as a data frame.
When `name` is supplied and `value` is `NULL`, returns the value of that
setting. When both `name` and `value` are supplied, executes
`SET <name> = <value>`.

## Usage

``` r
conn_setting(conn = conn_default(), name = NULL, value = NULL)
```

## Arguments

- conn:

  A DuckDB connection.

- name:

  Optional character scalar. Setting name.

- value:

  Optional value to set. Coerced to character; DuckDB casts it to the
  appropriate type.

## Value

All settings: a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html).
Single setting read: a character scalar. Write: `conn` invisibly.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
conn_setting(conn, "threads")
#> [1] "4"
DBI::dbDisconnect(conn, shutdown = TRUE)
```
