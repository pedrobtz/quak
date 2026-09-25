test_that("collect_arrow returns the whole result as an in-memory stream", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)

  out <- collect_arrow(tagged |> dplyr::filter(i >= 5))

  expect_s3_class(out, "nanoarrow_array_stream")
  df <- as.data.frame(out)
  expect_named(df, c("i", "j"))
  expect_equal(nrow(df), 20L)
  expect_equal(df$j, df$i * 2)
})

test_that("collect_arrow returns every row when the result spans batches", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn, n = 1500000L)

  batches <- nanoarrow::collect_array_stream(collect_arrow(tagged))

  expect_gt(length(batches), 1L)
  expect_equal(sum(vapply(batches, function(b) b$length, integer(1))), 1500000L)
})

test_that("collect_arrow leaves the connection free for other queries", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)

  out <- collect_arrow(tagged)
  DBI::dbGetQuery(conn, "SELECT 42")

  expect_equal(nrow(as.data.frame(out)), 25L)
})

test_that("collect_arrow returns an empty stream for an empty result", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn, n = 0L)

  df <- as.data.frame(collect_arrow(tagged))

  expect_equal(nrow(df), 0L)
  expect_named(df, c("i", "j"))
})

test_that("collect_arrow handles nested and interval columns, empty or not", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  local_mocked_bindings(check_tbl_az = function(x, ...) invisible(x))
  local_opt("collect_verbose", FALSE)
  DBI::dbExecute(
    conn,
    "CREATE TABLE nested AS
     SELECT [i, i + 1] AS l, {'a': i} AS st, INTERVAL 1 DAY AS iv
     FROM range(3) t(i)"
  )
  tagged <- new_tbl_az(dplyr::tbl(conn, "nested"))

  for (n in c(3L, 0L)) {
    out <- collect_arrow(dplyr::filter(tagged, st$a < n))
    expect_named(out$get_schema()$children, c("l", "st", "iv"))
    batches <- nanoarrow::collect_array_stream(out)
    expect_equal(sum(vapply(batches, function(b) b$length, integer(1))), n)
  }
})

test_that("as.data.frame(collect_arrow()) matches collect()", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  local_mocked_bindings(check_tbl_az = function(x, ...) invisible(x))
  local_opt("collect_verbose", FALSE)
  DBI::dbExecute(
    conn,
    "CREATE TABLE typed AS
     SELECT i::BIGINT AS big, i::VARCHAR AS s, i > 0 AS lgl,
            DATE '2026-01-01' + i::INTEGER AS d, [i, i + 1] AS l
     FROM range(3) t(i)"
  )
  tagged <- new_tbl_az(dplyr::tbl(conn, "typed"))

  expect_equal(
    as.data.frame(collect_arrow(tagged)),
    as.data.frame(dplyr::collect(tagged)),
    ignore_attr = TRUE
  )
})

test_that("collect_arrow reports rows and elapsed time when verbose", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)
  local_opt("collect_verbose", TRUE)

  expect_message(
    collect_arrow(tagged),
    "Done\\. 25 rows collected in [0-9.]+ (ms|s)\\."
  )
})

test_that("stream_arrow yields batches of at most chunk_size rows", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)

  stream <- stream_arrow(tagged, chunk_size = 10)

  expect_s3_class(stream, "nanoarrow_array_stream")
  batches <- nanoarrow::collect_array_stream(stream)
  expect_equal(
    vapply(batches, function(b) b$length, integer(1)),
    c(10L, 10L, 5L)
  )
})

test_that("stream_arrow stays readable after the call returns", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)

  stream <- stream_arrow(tagged)
  gc()

  expect_equal(nrow(as.data.frame(stream)), 25L)
})

test_that("stream_arrow rejects an invalid chunk_size", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  tagged <- local_arrow_tbl(conn)

  for (bad in list(0, -1, 1.5, "10", c(1, 2), NA_real_)) {
    expect_error(
      stream_arrow(tagged, chunk_size = bad),
      class = "quak_error_bad_argument"
    )
  }
})

test_that("collect_arrow and stream_arrow reject tables that are not tbl_az", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- local_ext_conn()
  DBI::dbWriteTable(conn, "plain", data.frame(a = 1:3))
  plain <- dplyr::tbl(conn, "plain")

  expect_error(collect_arrow(plain), class = "quak_error_bad_argument")
  expect_error(stream_arrow(plain), class = "quak_error_bad_argument")
  expect_error(
    collect_arrow(data.frame(a = 1)),
    class = "quak_error_bad_argument"
  )
})

test_that("collect_arrow and stream_arrow run the tbl_az pre-flight checks", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("nanoarrow")
  conn <- conn_open()
  DBI::dbWriteTable(conn, "demo", data.frame(a = 1:3))
  tagged <- new_tbl_az(dplyr::tbl(conn, "demo"))
  DBI::dbDisconnect(conn, shutdown = TRUE)

  expect_error(collect_arrow(tagged), class = "quak_error_connection_closed")
  expect_error(stream_arrow(tagged), class = "quak_error_connection_closed")
})
