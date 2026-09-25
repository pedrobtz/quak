test_that("Delta SQL builders render DuckDB Delta functions", {
  conn <- local_ext_conn()

  expect_match(
    as.character(sql_delta_files("abfss://c@a/table", conn)),
    "delta_list_files"
  )
})

test_that("az_delta_files rejects non-Azure URLs before I/O", {
  conn <- local_ext_conn()

  expect_error(
    az_delta_files(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("az_delta_files wraps DuckDB query failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    check_azure_url = function(url) url,
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    sql_delta_files = function(...) DBI::SQL("SELECT * FROM missing_table")
  )

  err <- rlang::catch_cnd(
    az_delta_files(conn, "abfss://c@a/table"),
    classes = "error"
  )

  expect_s3_class(err, "quak_error_azure_query_failed")
  expect_s3_class(err$parent, "error")
})
