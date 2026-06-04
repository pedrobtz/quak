# Build an extension download URL

Combines a repository base URL with the running DuckDB version and
platform to produce the full path to an extension archive. When
`repo_url` is supplied it overrides the configured `repo` URL.

## Usage

``` r
ext_url(
  ext,
  repo = c("core", "community"),
  repo_url = NULL,
  conn = conn_default()
)
```

## Arguments

- ext:

  Character scalar. Extension name.

- repo:

  `"core"` or `"community"`. Selects which configured repository URL to
  use. Ignored when `repo_url` is non-`NULL`.

- repo_url:

  Optional character scalar. Explicit base URL overriding `repo`'s
  configured URL.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

A character scalar URL.
