# Tune Azure read settings on a DuckDB connection

Sets the Azure performance and transport settings exposed by DuckDB.
Each argument defaults to `NULL`, which leaves that setting unchanged.

## Usage

``` r
az_tune(
  conn,
  concurrency = NULL,
  chunk_size = NULL,
  buffer_size = NULL,
  transport = NULL,
  metadata_cache = NULL,
  context_cache = NULL
)
```

## Arguments

- conn:

  A DuckDB connection.

- concurrency:

  Optional positive whole number for `azure_read_transfer_concurrency`.

- chunk_size:

  Optional positive whole number or character scalar for
  `azure_read_transfer_chunk_size`.

- buffer_size:

  Optional positive whole number or character scalar for
  `azure_read_buffer_size`.

- transport:

  Optional character scalar for `azure_transport_option_type`.

- metadata_cache:

  Optional logical scalar for `enable_http_metadata_cache`.

- context_cache:

  Optional logical scalar for `azure_context_caching`.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_tune(conn, concurrency = 8, metadata_cache = TRUE)
} # }
```
