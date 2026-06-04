test_that("conn_info reports version and platform", {
  conn <- local_ext_conn()
  info <- conn_info(conn)
  expect_named(info, c("version", "platform"))
  expect_true(is.character(info$version) && nzchar(info$version))
  expect_true(is.character(info$platform) && nzchar(info$platform))
})

test_that("conn_setting returns all settings as a data frame", {
  conn <- local_ext_conn()
  all <- conn_setting(conn)
  expect_s3_class(all, "data.frame")
  expect_true("name" %in% names(all))
})

test_that("conn_setting reads a single known setting", {
  conn <- local_ext_conn()
  val <- conn_setting(conn, "threads")
  expect_type(val, "character")
  expect_length(val, 1L)
})

test_that("conn_setting warns on an unknown setting and returns NULL", {
  conn <- local_ext_conn()
  expect_warning(
    res <- conn_setting(conn, "definitely_not_a_setting"),
    "Unknown",
    class = "quak_warning_unknown_setting"
  )
  expect_null(res)
})

test_that("conn_setting rejects invalid setting names on write", {
  conn <- local_ext_conn()
  expect_error(conn_setting(conn, "bad name!", "x"), "letters, digits")
})

test_that("conn_setting rejects a non-string name", {
  conn <- local_ext_conn()
  expect_error(conn_setting(conn, name = 1L), "character scalar")
})

test_that("conn_setting writes a setting and returns conn invisibly", {
  conn <- local_ext_conn()
  original <- conn_setting(conn, "threads")
  withr::defer(conn_setting(conn, "threads", original))
  result <- conn_setting(conn, "threads", "1")
  expect_identical(result, conn)
  expect_equal(conn_setting(conn, "threads"), "1")
})

test_that("az_tune maps arguments to DuckDB settings", {
  conn <- local_ext_conn()
  seen <- list()
  local_mocked_bindings(
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    az_set_tune_setting = function(conn, name, value) {
      seen[[name]] <<- value
      invisible(conn)
    }
  )

  result <- az_tune(
    conn,
    concurrency = 8,
    chunk_size = 1024,
    buffer_size = 2048,
    transport = "curl",
    metadata_cache = TRUE,
    context_cache = FALSE
  )

  expect_identical(result, conn)
  expect_equal(seen$azure_read_transfer_concurrency, 8)
  expect_equal(seen$azure_read_transfer_chunk_size, 1024)
  expect_equal(seen$azure_read_buffer_size, 2048)
  expect_equal(seen$azure_transport_option_type, "curl")
  expect_equal(seen$enable_http_metadata_cache, TRUE)
  expect_equal(seen$azure_context_caching, FALSE)
})

test_that("az_tune warns when buffer size is not a chunk multiple", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL),
    az_get_tune_setting = function(conn, name) "1024",
    az_set_tune_setting = function(conn, name, value) invisible(conn)
  )

  expect_warning(
    az_tune(conn, buffer_size = 1500),
    "not evenly divisible",
    class = "quak_warning_azure_tune_buffer_size"
  )
})

test_that("az_tune is quiet and wraps DuckDB setting failures", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    ensure_azure_exts = function(conn, delta = FALSE) invisible(NULL)
  )

  expect_no_message(az_tune(conn))
  expect_error(
    az_tune(conn, transport = "curl"),
    "Failed to set",
    class = "quak_error_azure_tune_failed"
  )
})

test_that("az_tune validates argument types", {
  conn <- local_ext_conn()
  expect_error(
    az_tune(conn, concurrency = 1.5),
    "positive whole",
    class = "quak_error_bad_argument"
  )
  expect_error(
    az_tune(conn, metadata_cache = "yes"),
    "TRUE",
    class = "quak_error_bad_argument"
  )
})
