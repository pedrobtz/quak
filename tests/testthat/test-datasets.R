# check_azure_url -------------------------------------------------------------

test_that("check_azure_url accepts abfss and abfs URLs", {
  expect_equal(
    check_azure_url("abfss://acct.dfs.core.windows.net/container/p"),
    "abfss://acct.dfs.core.windows.net/container/p"
  )
  expect_equal(
    check_azure_url("abfss://container/p"),
    "abfss://container/p"
  )
})

test_that("check_azure_url normalises the container@account form", {
  # DuckDB documents abfss://account.dfs.core.windows.net/container/path, and
  # only that form can be matched by an account-scoped secret.
  expect_equal(
    check_azure_url("abfss://container@acct.dfs.core.windows.net/p"),
    "abfss://acct.dfs.core.windows.net/container/p"
  )
  expect_equal(
    check_azure_url("abfs://container@acct/p"),
    "abfs://acct.dfs.core.windows.net/container/p"
  )
})

test_that("normalize_azure_url leaves documented forms untouched", {
  unchanged <- c(
    "abfss://acct.dfs.core.windows.net/container/data/*.parquet",
    "abfss://container/data/sales",
    "abfs://container/data"
  )
  for (url in unchanged) {
    expect_equal(normalize_azure_url(url), url)
  }
})

test_that("normalize_azure_url preserves globs and handles a bare prefix", {
  expect_equal(
    normalize_azure_url("abfss://c@acct/data/**/*.parquet"),
    "abfss://acct.dfs.core.windows.net/c/data/**/*.parquet"
  )
  # No trailing path at all.
  expect_equal(
    normalize_azure_url("abfss://c@acct"),
    "abfss://acct.dfs.core.windows.net/c"
  )
})

test_that("check_azure_url rejects non-Azure URLs", {
  expect_error(
    check_azure_url("https://example.com/x"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
  expect_error(
    check_azure_url("s3://bucket/key"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
  expect_error(
    check_azure_url(""),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

# Argument validation (aborts before any extension load / network) ------------

test_that("load_delta validates its arguments before any I/O", {
  conn <- NULL
  expect_error(
    load_delta(conn, url = 1L, name = "t"),
    "character scalar",
    class = "quak_error_bad_argument"
  )
  expect_error(
    load_delta(conn, url = "abfss://a/b", name = 1L),
    "character scalar"
  )
  expect_error(load_delta(conn, "abfss://a/b", "t", replace = "yes"), "TRUE")
  expect_error(load_delta(conn, "abfss://a/b", "t", method = "nope"), "method")
  expect_error(
    load_delta(conn, "not-a-url", "t"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("load_parquet validates its arguments before any I/O", {
  conn <- NULL
  expect_error(
    load_parquet(conn, 1L, "t"),
    "character scalar",
    class = "quak_error_bad_argument"
  )
  expect_error(load_parquet(conn, "abfss://a/b", 1L), "character scalar")
  expect_error(
    load_parquet(conn, "abfss://a/b", "t", hive_partitioning = "x"),
    "TRUE"
  )
  expect_error(load_parquet(conn, "abfss://a/b", "t", replace = "x"), "TRUE")
  expect_error(
    load_parquet(conn, "not-a-url", "t"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("load_dataset rejects arguments the target loader does not accept", {
  expect_error(
    load_dataset(NULL, "abfss://a/b", "t", format = "delta", bogus = TRUE),
    "not accepted",
    class = "quak_error_bad_argument"
  )
})

test_that("load_dataset validates the format", {
  expect_error(
    load_dataset(NULL, "abfss://a/b", "t", format = "iceberg"),
    "format"
  )
})

test_that("load_csv validates its arguments before any I/O", {
  conn <- NULL
  expect_error(
    load_csv(conn, 1L, "t"),
    "character scalar",
    class = "quak_error_bad_argument"
  )
  expect_error(load_csv(conn, "abfss://a/b", 1L), "character scalar")
  expect_error(load_csv(conn, "abfss://a/b", "t", replace = "x"), "TRUE")
  expect_error(
    load_csv(conn, "abfss://a/b", "t", replace = TRUE, "bad"),
    "reader options must be named",
    class = "quak_error_bad_argument"
  )
  expect_error(
    load_csv(conn, "not-a-url", "t"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("load_json validates its arguments before any I/O", {
  conn <- NULL
  expect_error(
    load_json(conn, 1L, "t"),
    "character scalar",
    class = "quak_error_bad_argument"
  )
  expect_error(load_json(conn, "abfss://a/b", 1L), "character scalar")
  expect_error(load_json(conn, "abfss://a/b", "t", replace = "x"), "TRUE")
  expect_error(
    load_json(conn, "abfss://a/b", "t", replace = TRUE, "bad"),
    "reader options must be named",
    class = "quak_error_bad_argument"
  )
  expect_error(
    load_json(conn, "not-a-url", "t"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

# SQL builders ----------------------------------------------------------------

test_that("sql_or_replace toggles the OR REPLACE clause", {
  expect_equal(sql_or_replace(TRUE), "OR REPLACE ")
  expect_equal(sql_or_replace(FALSE), "")
})

test_that("delta SQL builders embed the scan, URL, and clauses", {
  conn <- local_ext_conn()
  url <- "abfss://c@a.dfs.core.windows.net/t"
  expect_match(as.character(sql_delta_scan(url, conn)), "delta_scan\\(")
  expect_match(as.character(sql_delta_scan(url, conn)), url, fixed = TRUE)
  expect_match(as.character(sql_delta_attach(url, "tbl", TRUE, conn)), "ATTACH")
  expect_match(
    as.character(sql_delta_attach(url, "tbl", TRUE, conn)),
    "OR REPLACE"
  )
  expect_match(
    as.character(sql_delta_attach(url, "tbl", FALSE, conn)),
    "TYPE DELTA"
  )
  expect_match(
    as.character(sql_delta_view(url, "v", TRUE, conn)),
    "CREATE OR REPLACE VIEW"
  )
  expect_match(
    as.character(sql_delta_attach(url, "tbl", TRUE, conn, version = 2)),
    "VERSION 2"
  )
  # DuckDB's delta extension accepts a TIMESTAMP attach option and ignores it,
  # so quak refuses it rather than returning the latest snapshot silently.
  expect_error(
    sql_delta_attach(url, "tbl", TRUE, conn, timestamp = "2024-01-01"),
    "not supported",
    class = "quak_error_bad_argument"
  )
  expect_false(grepl(
    "TIMESTAMP",
    as.character(sql_delta_attach(url, "tbl", TRUE, conn, version = 2))
  ))
  expect_error(
    sql_delta_attach(url, "tbl", TRUE, conn, version = 1, timestamp = "x"),
    "Only one",
    class = "quak_error_bad_argument"
  )
})

test_that("parquet SQL builders embed read_parquet and its options", {
  conn <- local_ext_conn()
  url <- "abfss://c@a/data/*.parquet"
  s <- as.character(sql_parquet_scan(url, TRUE, conn))
  expect_match(s, "read_parquet\\(")
  expect_match(s, "hive_partitioning")
  expect_match(s, "union_by_name")
  expect_match(
    as.character(sql_parquet_view(url, "v", FALSE, FALSE, conn)),
    "CREATE VIEW"
  )
})

test_that("CSV and JSON SQL builders embed reader options", {
  conn <- local_ext_conn()
  csv <- as.character(sql_csv_scan(
    "abfss://c@a/data/*.csv",
    conn,
    list(header = TRUE, delim = ",")
  ))
  json <- as.character(sql_json_scan(
    "abfss://c@a/data/*.json",
    conn,
    list(maximum_object_size = 1000)
  ))

  expect_match(csv, "read_csv_auto")
  expect_match(csv, "header = true")
  expect_match(csv, "delim = ','")
  expect_match(json, "read_json_auto")
  expect_match(json, "maximum_object_size = 1000")
  expect_match(
    as.character(sql_csv_view(
      "abfss://c@a/data/*.csv",
      "v",
      TRUE,
      conn,
      list(header = TRUE)
    )),
    "CREATE OR REPLACE VIEW"
  )
})

# load_dataset reader-option forwarding ---------------------------------------

test_that("load_dataset forwards reader options to loaders taking `...`", {
  # Regression: the explicit-formals allowlist used to reject every CSV/JSON
  # reader option, making load_dataset() less capable than the loaders it wraps.
  called <- NULL
  local_mocked_bindings(
    load_csv = function(conn, url, name, ...) {
      called <<- list(...)
      invisible(conn)
    }
  )
  load_dataset(NULL, "abfss://a/b.csv", "t", format = "csv", header = TRUE)
  expect_equal(called, list(header = TRUE))
})

test_that("load_dataset still rejects bad arguments for loaders without `...`", {
  expect_error(
    load_dataset(NULL, "abfss://a/b", "t", format = "delta", bogus = TRUE),
    "not accepted",
    class = "quak_error_bad_argument"
  )
  expect_error(
    load_dataset(NULL, "abfss://a/b", "t", format = "parquet", header = TRUE),
    "not accepted",
    class = "quak_error_bad_argument"
  )
})

test_that("load_dataset leaves reader-option validation to the loader", {
  # Forwarding does not weaken validation: load_csv() still rejects option
  # names that cannot be a DuckDB reader option, before any remote work.
  expect_error(
    load_dataset(
      NULL,
      "abfss://a/b.csv",
      "t",
      format = "csv",
      `bad name` = 1
    ),
    "invalid reader option",
    class = "quak_error_bad_argument"
  )
})
