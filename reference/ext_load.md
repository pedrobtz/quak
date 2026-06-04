# Load a DuckDB extension, installing it first if necessary

When `path` is supplied, executes `LOAD '/path/to/ext.duckdb_extension'`
directly — no install check or auto-install occurs. When only `name` is
supplied, returns immediately if the extension is already loaded.
Otherwise it checks whether the extension is installed; if not and
`auto_install = TRUE`, installs it (prompting first when `ask = TRUE`
and the session is interactive), then executes `LOAD <name>`.

## Usage

``` r
ext_load(
  name = NULL,
  path = NULL,
  conn = conn_default(),
  auto_install = TRUE,
  ask = rlang::is_interactive(),
  cache = ext_cache(),
  repo = c("core", "community")
)
```

## Arguments

- name:

  Character scalar. Extension name. When `path` is supplied, `name` is
  inferred from the filename and used only in messages.

- path:

  Optional character scalar. Path to a local `.duckdb_extension` file.
  When supplied, the extension is loaded directly from disk, bypassing
  the install check and
  [`ext_install()`](https://pedrobtz.github.io/quak/reference/ext_install.md).

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

- auto_install:

  Logical. Install automatically when the extension is missing. Default
  `TRUE`. Ignored when `path` is supplied.

- ask:

  Logical. Prompt the user before installing. Defaults to
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html),
  so it never prompts during tests or in non-interactive sessions.
  Ignored when `auto_install = FALSE` or `path` is supplied.

- cache:

  An `ext_cache` object forwarded to
  [`ext_install()`](https://pedrobtz.github.io/quak/reference/ext_install.md)
  on auto-install. Ignored when `path` is supplied.

- repo:

  `"core"` or `"community"`. Forwarded to
  [`ext_install()`](https://pedrobtz.github.io/quak/reference/ext_install.md).
  Ignored when `path` is supplied.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires network access to download and load the extension.
conn <- DBI::dbConnect(duckdb::duckdb())
ext_load("httpfs", conn = conn)
DBI::dbDisconnect(conn, shutdown = TRUE)
} # }
```
