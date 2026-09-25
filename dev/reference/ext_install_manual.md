# Install an extension manually using the cache

Looks the extension up in `cache`. On a hit the cached
`.duckdb_extension` file is copied into the connection's
`extension_directory`. On a miss `ext_download()` is invoked first to
populate the cache, and the freshly-cached file is copied.

## Usage

``` r
ext_install_manual(
  name,
  cache = ext_cache(),
  repo = "core",
  conn = conn_default()
)
```

## Arguments

- name:

  Character scalar. Extension name.

- cache:

  An `ext_cache` object.

- repo:

  `"core"` or `"community"`. Forwarded to `ext_download()` on cache
  miss.

- conn:

  A DuckDB connection.

## Value

Invisibly returns `conn`.
