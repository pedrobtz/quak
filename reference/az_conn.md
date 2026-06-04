# Open a DuckDB connection configured for Azure Data Lake Storage Gen2

Opens a DuckDB connection and installs the `azure` and `delta`
extensions. No secret is registered — use
[`az_set_token_secret()`](https://pedrobtz.github.io/quak/reference/az_set_token_secret.md),
[`az_set_sp_secret()`](https://pedrobtz.github.io/quak/reference/az_set_sp_secret.md),
or
[`az_set_chain_secret()`](https://pedrobtz.github.io/quak/reference/az_set_chain_secret.md)
to supply credentials afterwards.

## Usage

``` r
az_conn(conn = NULL)
```

## Arguments

- conn:

  An existing DuckDB connection to configure. When `NULL` (default) a
  new in-memory connection is opened via
  [`conn_open()`](https://pedrobtz.github.io/quak/reference/conn_open.md).

## Value

A DuckDB connection. The caller owns its lifetime; disconnect with
`DBI::dbDisconnect(conn, shutdown = TRUE)`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn() |>
  az_set_token_secret(token = my_token)
DBI::dbDisconnect(conn, shutdown = TRUE)
} # }
```
