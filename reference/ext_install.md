# Install a DuckDB extension

Tries two strategies in order, succeeding as soon as one works:

## Usage

``` r
ext_install(
  name,
  cache = ext_cache(),
  repo = c("core", "community"),
  conn = conn_default(),
  verbose = NULL
)
```

## Arguments

- name:

  Character scalar. Extension name.

- cache:

  An `ext_cache` object used by the manual fallback.

- repo:

  `"core"` or `"community"`. Determines which configured URL to use and,
  when no URL is set, which DuckDB install syntax to emit.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

- verbose:

  Logical or `NULL`. When `TRUE`, emits a warning if the SQL install
  fails but the manual fallback succeeds. When `NULL` (default), uses
  the `quak.install_verbose` option / `QUAK_INSTALL_VERBOSE` env var.
  When `FALSE`, the fallback is silent. Either way, a SQL failure is
  never raised as an error on its own.

## Value

Invisibly returns `conn`.

## Details

1.  **SQL install:** runs DuckDB's built-in `INSTALL` (using the
    configured repository URL when one is set via
    [`repo_set_urls()`](https://pedrobtz.github.io/quak/reference/repo_set_urls.md),
    the `QUAK_CORE_REPO` / `QUAK_COMMUNITY_REPO` env vars, or the
    `quak.core_repo` / `quak.community_repo` R options).

2.  **Manual fallback:** when the SQL install fails (e.g. DuckDB cannot
    reach an HTTPS URL before `httpfs` is loaded, whereas R's `curl`
    can), downloads the `.duckdb_extension` file, caches it, and copies
    it into the extension directory.

A SQL failure is never raised on its own — it only surfaces (as a
warning, when `verbose = TRUE`) if the manual fallback also runs. An
error is raised only when both strategies fail.

Idempotent — skips install if the extension is already installed
(checked via the `duckdb_extensions()` pragma).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires network access to download the extension.
conn <- DBI::dbConnect(duckdb::duckdb())
ext_install("httpfs", conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
} # }
```
