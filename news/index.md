# Changelog

## quak 0.1.1

CRAN release: 2026-09-28

- New
  [`collect_arrow()`](https://pedrobtz.github.io/quak/reference/collect_arrow.md)
  and
  [`stream_arrow()`](https://pedrobtz.github.io/quak/reference/stream_arrow.md)
  return the result of a lazy Azure table as Arrow data, either all at
  once or in batches, without converting it to a data frame. They need
  the nanoarrow package. The new “Arrow output” article on the package
  website shows how to use them with arrow.

- New “DuckDB connection settings” article on the package website
  explains which DuckDB settings to change for shared servers,
  containers and large queries.

- quak now requires duckdb 1.5.4 or later and DBI 1.2.0 or later, the
  first releases with the DBI Arrow interface. It also declares R 4.1.0
  or later, which it already needed.

- The extension repository check now runs when quak is attached rather
  than when it is loaded. It reports through startup messages, which
  [`suppressPackageStartupMessages()`](https://rdrr.io/r/base/message.html)
  silences. It gives up on a repository after 10 seconds without a
  connection, and never stops quak from loading.

### Bug fixes

- The default extension cache directory is now worked out on the machine
  where quak runs. It was worked out when the package was built, so
  binary packages pointed it at the build machine’s home directory, for
  example `/home/builder/.cache/R/quak`. When DuckDB’s own `INSTALL`
  failed, the manual install then stopped with “permission denied”
  ([\#15](https://github.com/pedrobtz/quak/issues/15)).

- [`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md),
  [`load_delta()`](https://pedrobtz.github.io/quak/reference/load_delta.md),
  [`az_delta_files()`](https://pedrobtz.github.io/quak/reference/az_delta_files.md)
  and the Delta readers behind
  [`az_schema()`](https://pedrobtz.github.io/quak/reference/az_schema.md)
  and
  [`az_glimpse()`](https://pedrobtz.github.io/quak/reference/az_glimpse.md)
  work again. They passed the `delta` extension the account-host URL
  form (`abfss://account.dfs.core.windows.net/container/path`), which it
  rejects with “URL did not match any known pattern”. They now pass
  `abfss://container@account.dfs.core.windows.net/path`. Delta tables
  never match an account-scoped secret, so use an unscoped secret for
  them ([\#18](https://github.com/pedrobtz/quak/issues/18)).

- [`load_delta()`](https://pedrobtz.github.io/quak/reference/load_delta.md)
  and
  [`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md)
  no longer accept `timestamp`. DuckDB’s `delta` extension accepts a
  `TIMESTAMP` attach option but ignores it, so callers silently received
  the latest snapshot instead of a historical one. Supplying `timestamp`
  now raises an error; use `version`, which DuckDB does honour
  ([\#2](https://github.com/pedrobtz/quak/issues/2)).

- Account-scoped Azure secrets are now scoped to the account’s actual
  hosts (`abfss://<account>.dfs.core.windows.net/` and
  `az://<account>.blob.core.windows.net/`) rather than
  `abfss://<account>/`, which matched no real URL. Account secrets
  registered by
  [`az_set_token_secret()`](https://pedrobtz.github.io/quak/reference/az_set_token_secret.md),
  [`az_set_sp_secret()`](https://pedrobtz.github.io/quak/reference/az_set_sp_secret.md)
  and
  [`az_set_chain_secret()`](https://pedrobtz.github.io/quak/reference/az_set_chain_secret.md)
  were therefore never selected, letting queries fall back to another
  secret or to anonymous access
  ([\#3](https://github.com/pedrobtz/quak/issues/3)).

- Azure URLs written as `abfss://container@account/path` are now
  normalised to `abfss://account.dfs.core.windows.net/container/path`.
  The former is not a URL form DuckDB supports, and no account-scoped
  secret could match it
  ([\#3](https://github.com/pedrobtz/quak/issues/3)).

- [`az_copy_to()`](https://pedrobtz.github.io/quak/reference/az_copy_to.md)
  and
  [`az_write_parquet()`](https://pedrobtz.github.io/quak/reference/az_write_parquet.md)
  now reject a lazy table that belongs to a different connection than
  `conn`, instead of rendering its SQL and running it against `conn` —
  which silently exported the wrong rows when both connections held a
  table of the same name
  ([\#4](https://github.com/pedrobtz/quak/issues/4)).

- [`load_dataset()`](https://pedrobtz.github.io/quak/reference/load_dataset.md)
  now forwards reader options to
  [`load_csv()`](https://pedrobtz.github.io/quak/reference/load_csv.md)
  and
  [`load_json()`](https://pedrobtz.github.io/quak/reference/load_json.md).
  Valid options such as `header` and `maximum_object_size` were rejected
  before reaching the loader, making the dispatcher less capable than
  the loaders it wraps
  ([\#5](https://github.com/pedrobtz/quak/issues/5)).

## quak 0.1.0

CRAN release: 2026-06-09

- First version.
