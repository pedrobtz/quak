# Changelog

## quak (development version)

- New
  [`collect_arrow()`](https://pedrobtz.github.io/quak/dev/reference/collect_arrow.md)
  and
  [`stream_arrow()`](https://pedrobtz.github.io/quak/dev/reference/stream_arrow.md)
  return the result of a lazy Azure table as Arrow data, either all at
  once or in batches, without converting it to a data frame. They need
  the nanoarrow package. The new “Arrow output” article on the package
  website shows how to use them with arrow.

- New “DuckDB connection settings” article on the package website
  explains which DuckDB settings to change for shared servers,
  containers and large queries.

- quak now requires duckdb 1.5.4 or later, the first release with the
  DBI Arrow interface.

### Bug fixes

- [`load_delta()`](https://pedrobtz.github.io/quak/dev/reference/load_delta.md)
  and
  [`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md)
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
  [`az_set_token_secret()`](https://pedrobtz.github.io/quak/dev/reference/az_set_token_secret.md),
  [`az_set_sp_secret()`](https://pedrobtz.github.io/quak/dev/reference/az_set_sp_secret.md)
  and
  [`az_set_chain_secret()`](https://pedrobtz.github.io/quak/dev/reference/az_set_chain_secret.md)
  were therefore never selected, letting queries fall back to another
  secret or to anonymous access
  ([\#3](https://github.com/pedrobtz/quak/issues/3)).

- Azure URLs written as `abfss://container@account/path` are now
  normalised to `abfss://account.dfs.core.windows.net/container/path`.
  The former is not a URL form DuckDB supports, and no account-scoped
  secret could match it
  ([\#3](https://github.com/pedrobtz/quak/issues/3)).

- [`az_copy_to()`](https://pedrobtz.github.io/quak/dev/reference/az_copy_to.md)
  and
  [`az_write_parquet()`](https://pedrobtz.github.io/quak/dev/reference/az_write_parquet.md)
  now reject a lazy table that belongs to a different connection than
  `conn`, instead of rendering its SQL and running it against `conn` —
  which silently exported the wrong rows when both connections held a
  table of the same name
  ([\#4](https://github.com/pedrobtz/quak/issues/4)).

- [`load_dataset()`](https://pedrobtz.github.io/quak/dev/reference/load_dataset.md)
  now forwards reader options to
  [`load_csv()`](https://pedrobtz.github.io/quak/dev/reference/load_csv.md)
  and
  [`load_json()`](https://pedrobtz.github.io/quak/dev/reference/load_json.md).
  Valid options such as `header` and `maximum_object_size` were rejected
  before reaching the loader, making the dispatcher less capable than
  the loaders it wraps
  ([\#5](https://github.com/pedrobtz/quak/issues/5)).

## quak 0.1.0

CRAN release: 2026-06-09

- First version.
