#' Collect an Azure-backed lazy tbl as Arrow data
#'
#' Runs the query behind a table created by [tbl_delta()], [tbl_parquet()],
#' [tbl_csv()] or [tbl_json()] and returns the whole result as a single
#' Arrow array, without converting it to an R data frame. Runs the same
#' pre-flight checks as [collect.tbl_az()].
#'
#' Requires the \pkg{nanoarrow} package. Use [stream_arrow()] to read a
#' large result in batches instead.
#'
#' @section Converting the result:
#' `as.data.frame()` and `tibble::as_tibble()` convert the array with
#' \pkg{nanoarrow}. The column types mostly match [collect.tbl_az()], with
#' these exceptions:
#'
#' * `INTERVAL` columns cannot be converted. Cast them in the query, or
#'   convert through `arrow::as_arrow_table()`.
#' * `TIME` columns become `hms` rather than `difftime`.
#' * `BLOB` columns become `blob` rather than a plain list.
#'
#' @param x A `tbl_az` produced by [tbl_delta()], [tbl_parquet()],
#'   [tbl_csv()] or [tbl_json()].
#' @return A `nanoarrow_array` with one struct column per result column.
#' @seealso [stream_arrow()] to read the result in batches.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' sales <- tbl_delta(conn, "abfss://container@account/path/sales")
#' arr <- collect_arrow(sales)
#' as.data.frame(arr)
#' arrow::as_arrow_table(arr)
#' }
#' @export
collect_arrow <- function(x) {
  src <- arrow_source(x)
  collect_inform_start()
  start <- proc.time()[["elapsed"]]
  # A batch as large as possible holds the whole result. Combining several
  # batches into one array would need the arrow package.
  stream <- arrow_stream(src, chunk_size = .Machine$integer.max)
  on.exit(stream$release(), add = TRUE)
  schema <- stream$get_schema()
  batches <- nanoarrow::collect_array_stream(stream)
  if (length(batches) > 1L) {
    abort_bad_arg(
      c(
        "The result has more than {.Machine$integer.max} rows, too many for one array.",
        "i" = "Use {.fn stream_arrow} to read it in batches."
      ),
      arg = "x"
    )
  }
  # Build an empty result from the schema natively. DBI::dbFetchArrowChunk()
  # goes through an R prototype instead, which fails for LIST and INTERVAL.
  result <- if (length(batches) == 0L) {
    nanoarrow::nanoarrow_array_init(schema)
  } else {
    batches[[1L]]
  }
  collect_inform_done(result$length, proc.time()[["elapsed"]] - start)
  result
}

#' Stream an Azure-backed lazy tbl as Arrow record batches
#'
#' Runs the query behind a table created by [tbl_delta()], [tbl_parquet()],
#' [tbl_csv()] or [tbl_json()] and returns a stream that yields the result
#' in batches of at most `chunk_size` rows. Batches are produced as they are
#' read, so the whole result never needs to fit in memory. Runs the same
#' pre-flight checks as [collect.tbl_az()].
#'
#' Requires the \pkg{nanoarrow} package. Read batches with
#' `stream$get_next()`, which returns `NULL` once the stream is exhausted,
#' or pass the stream to `arrow::as_record_batch_reader()`.
#'
#' @section Reading the stream:
#' Read the stream to the end before running any other query on the same
#' connection. DuckDB ends an open stream as soon as the connection runs
#' another query, and the stream then reports that it is exhausted without
#' an error, so the remaining rows are lost silently.
#'
#' To stop reading early, call `stream$release()`. It frees the query and
#' its buffers at once, rather than when R next collects garbage.
#'
#' @inheritParams collect_arrow
#' @param chunk_size Positive whole number. The maximum number of rows in
#'   each batch.
#' @return A `nanoarrow_array_stream`.
#' @seealso [collect_arrow()] to read the whole result at once.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' sales <- tbl_delta(conn, "abfss://container@account/path/sales")
#' stream <- stream_arrow(sales, chunk_size = 100000)
#' while (!is.null(batch <- stream$get_next())) {
#'   message(batch$length, " rows")
#' }
#' }
#' @export
stream_arrow <- function(x, chunk_size = 1e6) {
  if (!is_whole_number(chunk_size) || chunk_size <= 0) {
    abort_bad_arg(
      "{.arg chunk_size} must be a positive whole number.",
      arg = "chunk_size",
      value = chunk_size
    )
  }
  src <- arrow_source(x)
  arrow_stream(src, chunk_size = chunk_size)
}

arrow_stream <- function(src, chunk_size) {
  res <- DBI::dbSendQueryArrow(src$conn, src$sql)
  # The stream owns the query result, so clearing `res` leaves it readable.
  on.exit(DBI::dbClearResult(res), add = TRUE)
  DBI::dbFetchArrow(res, chunk_size = chunk_size)
}

arrow_source <- function(x, call = rlang::caller_env()) {
  rlang::check_installed("nanoarrow", reason = "to return Arrow data.")
  if (!inherits(x, "tbl_az")) {
    abort_bad_arg(
      c(
        "{.arg x} must be a table created by {.fn tbl_delta}, {.fn tbl_parquet}, {.fn tbl_csv} or {.fn tbl_json}.",
        "i" = "Use {.fn DBI::dbGetQueryArrow} for other DuckDB queries."
      ),
      arg = "x",
      value = x,
      call = call
    )
  }
  check_tbl_az(x, call = call)
  list(
    conn = dbplyr::remote_con(x),
    sql = as.character(dbplyr::sql_render(x))
  )
}
