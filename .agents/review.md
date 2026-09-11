# Review of `main`

Reviewed commit: `6a39eb893aad9059537a4a69da47dbca80ba815a`.

These are findings from reviewing the code on `main`, not regressions against
`origin/main`: both branches pointed to the same commit and that diff was empty.
The existing test suite reported **299 passed, one skipped, zero failures and
zero warnings**. Reproductions used R package `duckdb` **1.5.4.1** (DuckDB engine
**1.5.4**). Live Azure reads and writes were not tested.
All R snippets below were executed together and reproduced the stated results.

## Reproduction setup

Run these snippets from the repository root. `load_all()` makes the internal SQL
builders available. Each example uses temporary files and an in-memory database;
the helper closes connections and removes its temporary extension directory.
The first two examples require downloadable `delta` or `azure` extensions, but
neither requires Azure credentials. Extension installation can use quak's cache.

```r
devtools::load_all(quiet = TRUE)

with_review_conn <- function(run, extensions = character()) {
  conn <- conn_open()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  ext_path <- tempfile("quak-review-exts-")
  on.exit(unlink(ext_path, recursive = TRUE), add = TRUE)
  ext_set_dir(ext_path, conn)
  for (extension in extensions) {
    ext_load(extension, conn = conn, ask = FALSE)
  }
  run(conn)
}
```

## 1. [P1] Delta timestamps silently return current data

**Location:** [R/datasets.R](../R/datasets.R), lines 610–617,
`sql_delta_time_travel()`; affects `load_delta()` and `tbl_delta()`.

The builder emits `ATTACH ... (TYPE DELTA, TIMESTAMP '...')`, but the tested Delta
extension ignores that option. Both `timestamp = "1900-01-01"` and
`timestamp = "nonsense"` returned the current table without error. A caller can
therefore receive current data while believing it is a historical snapshot.
[DuckDB documents version-based Delta time travel](https://duckdb.org/docs/current/core_extensions/delta#time-travel).

### Reproduce

A small local Delta fixture avoids Azure authentication and isolates the emitted
SQL. The fixture is the longest part of the example: a Delta table needs a
transaction log as well as a Parquet file.

```r
with_review_conn(function(conn) {
  root <- tempfile("quak-review-delta-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  dir.create(file.path(root, "_delta_log"))
  parquet <- file.path(root, "data.parquet")
  DBI::dbExecute(conn, glue::glue_sql(
    "COPY (SELECT 7::INTEGER AS id) TO {parquet} (FORMAT PARQUET)",
    .con = conn
  ))
  log <- c(
    '{"protocol":{"minReaderVersion":1,"minWriterVersion":2}}',
    r'({"metaData":{"id":"review","format":{"provider":"parquet","options":{}},"schemaString":"{\"type\":\"struct\",\"fields\":[{\"name\":\"id\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}]}","partitionColumns":[],"configuration":{}}})',
    sprintf('{"add":{"path":"data.parquet","partitionValues":{},"size":%s,"modificationTime":1704067200000,"dataChange":true}}',
            file.info(parquet)$size)
  )
  writeLines(log, file.path(root, "_delta_log", "00000000000000000000.json"))

  for (timestamp in c("1900-01-01", "nonsense")) {
    DBI::dbExecute(conn, sql_delta_attach(
      root, "sales", conn = conn, timestamp = timestamp
    ))
    print(DBI::dbGetQuery(conn, "SELECT * FROM sales"))
    # Both return id = 7. Neither timestamp should return this current snapshot.
  }
}, extensions = "delta")
```

**Suggested fix:** Reject non-NULL `timestamp` with an actionable error until
timestamp lookup is implemented. To support it, resolve the requested time to a
Delta version and attach with `VERSION`, defining behavior before the first
commit. Update documentation accordingly. Add execution tests using at least two
versions with different rows; checking that SQL contains `TIMESTAMP` cannot
detect an ignored option.

## 2. [P1] Account-scoped secrets miss the intended paths

**Location:** [R/azure.R](../R/azure.R), lines 301–306,
`az_secret_scope_clause()`; shared by all three secret helpers.

For `account = "myaccount"`, the generated scope is `abfss://myaccount/`.
That prefix matches neither the package's `container@account` examples nor
DuckDB's fully qualified account URLs. Registration succeeds, but a query cannot
select that secret for the intended account. It can fall back to another matching
secret or anonymous access instead.
[DuckDB secret scopes are path prefixes](https://duckdb.org/docs/current/configuration/secrets_manager).

### Reproduce

```r
with_review_conn(function(conn) {
  az_set_token_secret(conn, token = "fake-review-token", account = "myaccount")
  urls <- c(
    "abfss://container@myaccount.dfs.core.windows.net/data/file.parquet",
    "abfss://myaccount.dfs.core.windows.net/container/data/file.parquet"
  )
  for (url in urls) {
    match <- DBI::dbGetQuery(conn, glue::glue_sql(
      "SELECT * FROM which_secret({url}, 'azure')", .con = conn
    ))
    print(nrow(match)) # 0 for both URLs; expected the account secret to match.
  }
}, extensions = "azure")
```

This verifies secret selection without a storage request. An end-to-end read
requires an accessible Azure dataset and valid credentials, which were not
provided for this review.

**Suggested fix:** Define and normalize the supported URL representation, then
generate its matching account scope. For DuckDB's fully qualified ADLS form, use
`abfss://myaccount.dfs.core.windows.net/`. Handle any additional advertised URL
forms explicitly rather than assuming that prefix covers them. Test
`which_secret()` for all supported forms and verify that a different account does
not match; checking only that a secret was created misses this defect.

## 3. [P1] Copying a lazy table can export another connection's data

**Location:** [R/lake.R](../R/lake.R), lines 393–395,
`az_copy_source_sql()`; affects `az_copy_to()` and `az_write_parquet()`.

For a lazy table, the helper renders `x` to SQL without checking its source
connection. `az_copy_to()` then runs that SQL on the supplied `conn`. If both
connections contain a table with the same name, the export can silently contain
the wrong rows. If the name is absent, it fails instead.

### Reproduce

```r
with_review_conn(function(source_conn) {
  with_review_conn(function(export_conn) {
    DBI::dbWriteTable(source_conn, "sales", data.frame(amount = 1))
    DBI::dbWriteTable(export_conn, "sales", data.frame(amount = 999))
    sales <- dplyr::tbl(source_conn, "sales")
    prepared <- az_copy_source_sql(export_conn, sales)
    print(DBI::dbGetQuery(export_conn, prepared$sql))
    # amount = 999, although the supplied lazy table contains amount = 1.
  })
})
```

This exercises the exact source SQL that the export executes. A complete Azure
write requires storage access and credentials; neither is needed to demonstrate
the incorrect source selection.

**Suggested fix:** Compare `dbplyr::remote_con(x)` with `conn` before rendering a
lazy table and reject a mismatch with a clear error. If cross-connection copying
is intended, transfer the source data explicitly rather than executing its SQL
against another database. Add a regression test with identically named tables
containing different rows, plus a same-connection success case.

## 4. [P2] Dataset dispatcher rejects valid CSV/JSON reader options

**Location:** [R/datasets.R](../R/datasets.R), lines 340–342,
`load_dataset()`.

The dispatcher allows only explicitly named formal arguments. `load_csv()` and
`load_json()` accept reader options through `...`, so valid options such as
`header` and `maximum_object_size` are rejected before reaching their loaders.

### Reproduce

```r
with_review_conn(function(conn) {
  print(tryCatch(
    load_dataset(conn, "abfss://container@account/data.csv", "sales",
                 format = "csv", header = TRUE),
    error = conditionMessage
  ))
  # Argument `header` not accepted by `load_csv()`.

  print(tryCatch(
    load_dataset(conn, "abfss://container@account/data.json", "events",
                 format = "json", maximum_object_size = 1000000),
    error = conditionMessage
  ))
  # Argument `maximum_object_size` not accepted by `load_json()`.
})
```

No extensions or Azure access are required: validation fails before any remote
operation.

**Suggested fix:** Apply the explicit-formals allowlist only to loaders without
`...`. For CSV/JSON loaders, forward named options and retain their existing
reader-option validation. Test forwarding through `load_dataset()` as well as
continued rejection of unsupported arguments for Delta/Parquet loaders.
