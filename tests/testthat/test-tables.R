local_tagged_tbl <- function(conn, name = "demo", env = parent.frame()) {
  DBI::dbWriteTable(conn, name, data.frame(a = 1:3, b = letters[1:3]))
  new_tbl_az(dplyr::tbl(conn, name))
}

test_that("new_tbl_az prepends the tbl_az class without dropping dbplyr classes", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- local_ext_conn()
  tagged <- local_tagged_tbl(conn)
  expect_s3_class(tagged, "tbl_az")
  expect_s3_class(tagged, "tbl_lazy")
  expect_identical(class(tagged)[[1]], "tbl_az")
})

test_that("collect.tbl_az aborts when the connection is closed", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- conn_open()
  tagged <- local_tagged_tbl(conn)
  DBI::dbDisconnect(conn, shutdown = TRUE)
  expect_error(
    dplyr::collect(tagged),
    "closed",
    class = "quak_error_connection_closed"
  )
})

test_that("check_tbl_az aborts when the azure extension is not loaded", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- local_ext_conn()
  tagged <- local_tagged_tbl(conn)
  expect_error(
    check_tbl_az(tagged),
    "azure",
    class = "quak_error_extension_not_loaded"
  )
})


test_that("collect.tbl_az dispatches to dbplyr once checks pass", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- local_ext_conn()
  skip_if(!ext_is_installed("azure", conn), "azure extension not installed")
  ext_load("azure", conn = conn, auto_install = FALSE, ask = FALSE)
  tagged <- local_tagged_tbl(conn)
  out <- dplyr::collect(tagged)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3L)
})

test_that("collect.tbl_az respects collect_verbose", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- local_ext_conn()
  tagged <- local_tagged_tbl(conn)
  local_mocked_bindings(
    check_tbl_az = function(x, ...) invisible(x)
  )
  old <- opts$get("collect_verbose")
  opts$set("collect_verbose", FALSE)
  withr::defer(opts$set("collect_verbose", old))
  out <- dplyr::collect(tagged)
  expect_no_message(dplyr::collect(tagged))
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3L)
})

test_that("collect.tbl_az reports elapsed collection time", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  conn <- local_ext_conn()
  tagged <- local_tagged_tbl(conn)
  local_mocked_bindings(
    check_tbl_az = function(x, ...) invisible(x)
  )
  old <- opts$get("collect_verbose")
  opts$set("collect_verbose", TRUE)
  withr::defer(opts$set("collect_verbose", old))

  expect_message(
    out <- dplyr::collect(tagged),
    "Done\\. 3 rows collected in [0-9.]+ (ms|s)\\."
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3L)
})

test_that("tbl_delta rejects non-Azure URLs before touching the network", {
  conn <- local_ext_conn()
  expect_error(
    tbl_delta(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("tbl_delta validates time travel arguments before touching the network", {
  conn <- local_ext_conn()
  expect_error(
    tbl_delta(conn, "abfss://a/b", version = 1, timestamp = "2024-01-01"),
    "Only one",
    class = "quak_error_bad_argument"
  )
  expect_error(
    tbl_delta(conn, "abfss://a/b", name = "t", timestamp = "2024-01-01"),
    "not supported",
    class = "quak_error_bad_argument"
  )
  expect_error(
    tbl_delta(conn, "abfss://a/b", version = 1),
    "name",
    class = "quak_error_bad_argument"
  )
  expect_error(
    tbl_delta(conn, "abfss://a/b", version = -1),
    "non-negative",
    class = "quak_error_bad_argument"
  )
})

test_that("tbl_parquet rejects non-Azure URLs before touching the network", {
  conn <- local_ext_conn()
  expect_error(
    tbl_parquet(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("tbl_csv rejects non-Azure URLs before touching the network", {
  conn <- local_ext_conn()
  expect_error(
    tbl_csv(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})

test_that("tbl_json rejects non-Azure URLs before touching the network", {
  conn <- local_ext_conn()
  expect_error(
    tbl_json(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
})
