test_that("unknown option errors include structured metadata", {
  err <- rlang::catch_cnd(opts$get("nonexistent"))

  expect_s3_class(err, "quak_error_unknown_option")
  expect_s3_class(err, "quak_error")
  expect_equal(err$option, "nonexistent")
  expect_setequal(err$valid, opts$.names)
})

test_that("invalid option errors include envvar and valid values", {
  old <- opts$get("collect_verbose")
  opts$set("collect_verbose", "maybe")
  withr::defer(opts$set("collect_verbose", old))

  err <- rlang::catch_cnd(opts$get("collect_verbose"))

  expect_s3_class(err, "quak_error_invalid_option")
  expect_equal(err$option, "collect_verbose")
  expect_equal(err$envvar, "QUAK_COLLECT_VERBOSE")
  expect_equal(err$valid, c("TRUE", "FALSE"))
})

test_that("invalid Azure URL errors include the URL", {
  err <- rlang::catch_cnd(check_azure_url("s3://bucket/key"))

  expect_s3_class(err, "quak_error_invalid_azure_url")
  expect_equal(err$url, "s3://bucket/key")
})

test_that("unknown DuckDB setting warnings include the setting name", {
  conn <- local_ext_conn()

  warn <- rlang::catch_cnd(
    conn_setting(conn, "definitely_not_a_setting"),
    classes = "warning"
  )

  expect_s3_class(warn, "quak_warning_unknown_setting")
  expect_s3_class(warn, "quak_warning")
  expect_equal(warn$setting, "definitely_not_a_setting")
})

test_that("extension unavailable errors include extension metadata and parent", {
  conn <- local_ext_conn()
  cache <- ext_cache(withr::local_tempdir())
  local_mocked_bindings(
    ext_download_file = function(...) stop("simulated download failure")
  )

  err <- rlang::catch_cnd(
    ext_download("json", cache = cache, conn = conn),
    classes = "error"
  )

  expect_s3_class(err, "quak_error_extension_unavailable")
  expect_equal(err$extension, "json")
  expect_type(err$platform, "character")
  expect_type(err$duckdb_version, "character")
  expect_match(err$url, "json\\.duckdb_extension\\.gz$")
  expect_s3_class(err$parent, "error")
})

test_that("extension load failures preserve the parent error", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    ext_is_loaded = function(...) FALSE,
    ext_is_installed = function(...) TRUE,
    ext_load_sql = function(...) stop("simulated load failure")
  )

  err <- rlang::catch_cnd(ext_load("json", conn = conn, auto_install = FALSE))

  expect_s3_class(err, "quak_error_extension_load_failed")
  expect_equal(err$extension, "json")
  expect_s3_class(err$parent, "error")
})
