# quak (development version)

## Bug fixes

* `load_delta()` and `tbl_delta()` no longer accept `timestamp`. DuckDB's
  `delta` extension accepts a `TIMESTAMP` attach option but ignores it, so
  callers silently received the latest snapshot instead of a historical one.
  Supplying `timestamp` now raises an error; use `version`, which DuckDB does
  honour (#2).

* Account-scoped Azure secrets are now scoped to the account's actual hosts
  (`abfss://<account>.dfs.core.windows.net/` and
  `az://<account>.blob.core.windows.net/`) rather than `abfss://<account>/`,
  which matched no real URL. Account secrets registered by
  `az_set_token_secret()`, `az_set_sp_secret()` and `az_set_chain_secret()`
  were therefore never selected, letting queries fall back to another secret
  or to anonymous access (#3).

* Azure URLs written as `abfss://container@account/path` are now normalised to
  `abfss://account.dfs.core.windows.net/container/path`. The former is not a
  URL form DuckDB supports, and no account-scoped secret could match it (#3).

* `az_copy_to()` and `az_write_parquet()` now reject a lazy table that belongs
  to a different connection than `conn`, instead of rendering its SQL and
  running it against `conn` — which silently exported the wrong rows when both
  connections held a table of the same name (#4).

* `load_dataset()` now forwards reader options to `load_csv()` and
  `load_json()`. Valid options such as `header` and `maximum_object_size` were
  rejected before reaching the loader, making the dispatcher less capable than
  the loaders it wraps (#5).

# quak 0.1.0

* First version.
