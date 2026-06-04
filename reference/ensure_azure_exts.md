# Ensure Azure-related extensions are loaded

Loads the `azure` extension and, optionally, the `delta` extension on
`conn`. Does not auto-install.

## Usage

``` r
ensure_azure_exts(conn, delta = FALSE)
```

## Arguments

- conn:

  A DuckDB connection.

- delta:

  Logical. Also load the `delta` extension.

## Value

Invisibly returns `NULL`; called for its side effect of loading the
`azure` (and optionally `delta`) extension onto `conn`.
