test_that("az_write_parquet writes data frames with DuckDB COPY", {
  conn <- local_ext_conn()
  path <- file.path(withr::local_tempdir(), "out.parquet")
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  out <- az_write_parquet(conn, data.frame(a = 1:3), path)

  expect_identical(out, path)
  expect_equal(
    DBI::dbGetQuery(conn, sql_parquet_scan(path, FALSE, conn))$a,
    1:3
  )
})

test_that("az_copy_to accepts SQL strings and COPY options", {
  conn <- local_ext_conn()
  path <- file.path(withr::local_tempdir(), "out.csv")
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  out <- az_copy_to(conn, "SELECT 1 AS a", path, format = "csv")

  expect_identical(out, path)
  expect_equal(DBI::dbGetQuery(conn, sprintf("SELECT * FROM '%s'", path))$a, 1L)
})

test_that("az_copy_to wraps COPY failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  expect_error(
    az_copy_to(conn, "SELECT * FROM missing_table", "abfss://c@a/out"),
    "Failed to copy",
    class = "quak_error_azure_copy_failed"
  )
})

test_that("az_copy_to wraps source preparation failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    az_copy_source_sql = function(...) stop("stage failed")
  )

  err <- rlang::catch_cnd(
    az_copy_to(conn, data.frame(a = 1), "abfss://c@a/out"),
    classes = "error"
  )

  expect_s3_class(err, "quak_error_azure_copy_failed")
  expect_s3_class(err$parent, "error")
})

test_that("az_glob and az_exists use DuckDB glob semantics", {
  skip_on_os("windows")
  conn <- local_ext_conn()
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "dataset"))
  writeLines("a\n1", file.path(dir, "dataset", "x.csv"))
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  expect_equal(
    normalizePath(az_glob(conn, file.path(dir, "dataset", "*.csv"))),
    normalizePath(file.path(dir, "dataset", "x.csv"))
  )
  expect_equal(az_exists(conn, file.path(dir, "dataset")), TRUE)
  expect_equal(az_exists(conn, file.path(dir, "missing")), FALSE)
})

test_that("az_glob and az_exists wrap DuckDB query failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    sql_glob = function(...) DBI::SQL("SELECT * FROM missing_table")
  )

  err <- rlang::catch_cnd(az_glob(conn, "abfss://c@a/*.csv"), classes = "error")
  expect_s3_class(err, "quak_error_azure_query_failed")
  expect_s3_class(err$parent, "error")
  expect_error(
    az_exists(conn, "abfss://c@a/*.csv"),
    "exists",
    class = "quak_error_azure_query_failed"
  )
})

test_that("az_schema infers formats and returns name/type columns", {
  conn <- local_ext_conn()
  dir <- withr::local_tempdir()
  path <- file.path(dir, "x.csv")
  writeLines("a,b\n1,x", path)
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  out <- az_schema(conn, path)

  expect_named(out, c("name", "type"))
  expect_equal(out$name, c("a", "b"))
})

test_that("az_schema wraps DuckDB query failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    sql_schema_query = function(...) DBI::SQL("SELECT * FROM missing_table")
  )

  err <- rlang::catch_cnd(
    az_schema(conn, "abfss://c@a/x.csv"),
    classes = "error"
  )

  expect_s3_class(err, "quak_error_azure_query_failed")
  expect_s3_class(err$parent, "error")
})


test_that("az_glimpse prints and invisibly returns the preview", {
  conn <- local_ext_conn()
  dir <- withr::local_tempdir()
  path <- file.path(dir, "x.csv")
  writeLines("a,b\n1,x\n2,y", path)
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  out <- az_glimpse(conn, path, n = 1)
  expect_output(print(out), "a")
  expect_equal(nrow(out), 1L)
})

test_that("az_glimpse wraps DuckDB query failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) invisible(NULL),
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    sql_preview_query = function(...) DBI::SQL("SELECT * FROM missing_table")
  )

  expect_error(
    az_glimpse(conn, "abfss://c@a/x.csv"),
    "preview",
    class = "quak_error_azure_query_failed"
  )
})

test_that("lake SQL builders render expected SQL", {
  conn <- local_ext_conn()
  copy_sql <- as.character(sql_copy_to(
    "SELECT 1 AS a",
    "abfss://c@a/out",
    "parquet",
    partition_by = "a",
    overwrite = TRUE,
    conn = conn
  ))

  expect_match(copy_sql, "COPY \\(SELECT 1 AS a\\) TO")
  expect_match(copy_sql, "FORMAT parquet")
  expect_match(copy_sql, "PARTITION_BY \\(a\\)")
  expect_match(copy_sql, "OVERWRITE_OR_IGNORE true")
  expect_match(
    as.character(sql_schema_query("abfss://c@a/x.parquet", "parquet", conn)),
    "DESCRIBE SELECT"
  )
})

test_that("az_resolve_format infers common lake formats", {
  expect_equal(az_resolve_format("abfss://c@a/x.parquet"), "parquet")
  expect_equal(az_resolve_format("abfss://c@a/x.csv"), "csv")
  expect_equal(az_resolve_format("abfss://c@a/x.jsonl"), "json")
  expect_error(
    az_resolve_format("abfss://c@a/table"),
    "Cannot infer",
    class = "quak_error_bad_argument"
  )
})
