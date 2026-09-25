# Install an extension via DuckDB's SQL INSTALL command

Install an extension via DuckDB's SQL INSTALL command

## Usage

``` r
ext_install_sql(
  name,
  repo = c("core", "community"),
  repo_url = NULL,
  conn = conn_default()
)
```

## Arguments

- name:

  Character scalar. Extension name.

- repo:

  `"core"` or `"community"`. Only relevant when `repo_url` is `NULL`:
  community extensions emit `INSTALL name FROM community`.

- repo_url:

  Character scalar or `NULL`. When non-`NULL`, emits
  `INSTALL name FROM 'url'`. When `NULL`, falls back to the
  repo-specific default: plain `INSTALL name` for core,
  `INSTALL name FROM community` for community.

- conn:

  A DuckDB connection.

## Value

Invisibly returns `conn`.
