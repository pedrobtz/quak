# Check which extension names are available in a repository

Sends a HEAD request for each name in `ext` against the given repository
and reports which ones the server serves (2xx). Use this to discover
which extensions are actually published for the running DuckDB version
and platform.

## Usage

``` r
repo_check(
  repo = c("core", "community"),
  ext = NULL,
  conn = conn_default(),
  verbose = FALSE
)
```

## Arguments

- repo:

  `"core"` or `"community"`.

- ext:

  Character vector of extension names to probe. Required.

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

Invisibly returns a named logical vector, one element per name in `ext`.
