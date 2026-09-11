#' Open a Delta Lake table as a lazy dplyr tbl
#'
#' Validates the URL, loads the `azure` and `delta` extensions, then returns a
#' lazy [dplyr::tbl()] over the table. Use [az_conn()] first if the connection
#' needs Azure extensions, settings, or secrets.
#'
#' When `name` is `NULL` the table is queried directly via `delta_scan()` with
#' no persistent object registered on the connection. When `name` is supplied
#' the table is first registered via [load_delta()] (as an ATTACH database or a
#' VIEW depending on `method`), then referenced by name.
#'
#' Delta time travel currently requires `name` because DuckDB exposes
#' `version` through `ATTACH`, not `delta_scan()`.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL pointing to a Delta table
#'   (e.g. `"abfss://container@account.dfs.core.windows.net/path/table"`).
#' @param name Optional character scalar. Name to register the table under in
#'   DuckDB. When `NULL` (default) the table is scanned directly.
#' @param method `"attach"` (default) or `"view"`. Ignored when `name = NULL`.
#' @param replace Logical. Replace an existing registration of the same name.
#'   Default `TRUE`. Ignored when `name = NULL`.
#' @param version Optional non-negative Delta table version to read.
#' @param timestamp Deprecated. Not supported: DuckDB's `delta` extension
#'   accepts a `TIMESTAMP` attach option but ignores it, returning the latest
#'   snapshot. Supplying it raises an error. Use `version` instead.
#' @return A [dplyr::tbl()] backed by the Delta table.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' tbl_delta(conn, "abfss://container@account/path/sales") |>
#'   dplyr::filter(amount > 100) |>
#'   dplyr::collect()
#' }
#' @export
tbl_delta <- function(
  conn,
  url,
  name = NULL,
  method = c("attach", "view"),
  replace = TRUE,
  version = NULL,
  timestamp = NULL
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  rlang::check_installed(c("dplyr", "dbplyr"))
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!is.null(name) && !rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar or {.code NULL}.",
      arg = "name",
      value = name
    )
  }
  check_delta_time_travel(version, timestamp)
  if (is.null(name) && !is.null(version)) {
    abort_bad_arg(
      "{.arg name} is required when using {.arg version}.",
      arg = "name",
      value = name
    )
  }
  method <- rlang::arg_match(method)
  out <- if (is.null(name)) {
    url <- check_azure_url(url)
    ensure_azure_exts(conn, delta = TRUE)
    dplyr::tbl(conn, dplyr::sql(sql_delta_scan(url, conn)))
  } else {
    load_delta(
      conn,
      url,
      name,
      method = method,
      replace = replace,
      version = version,
      timestamp = timestamp
    )
    dplyr::tbl(conn, name)
  }
  new_tbl_az(out)
}

#' Open a Parquet dataset as a lazy dplyr tbl
#'
#' Validates the URL, loads the `azure` extension, then returns a lazy
#' [dplyr::tbl()] over the dataset. Use [az_conn()] first if the connection
#' needs Azure extensions, settings, or secrets.
#'
#' When `name` is `NULL` the dataset is queried directly via `read_parquet()`
#' with no persistent object registered on the connection. When `name` is
#' supplied the dataset is first registered as a VIEW via [load_parquet()], then
#' referenced by name. Glob patterns (e.g. `"*.parquet"`) are supported in
#' `url` for multi-file datasets.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns for
#'   multi-file datasets
#'   (e.g. `"abfss://container@account.dfs.core.windows.net/data/*.parquet"`).
#' @param name Optional character scalar. Name to register the view under in
#'   DuckDB. When `NULL` (default) the dataset is scanned directly.
#' @param hive_partitioning Logical. Enable Hive partition inference from the
#'   directory structure. Default `FALSE`.
#' @param replace Logical. Replace an existing view of the same name.
#'   Default `TRUE`. Ignored when `name = NULL`.
#' @return A [dplyr::tbl()] backed by the Parquet dataset.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' tbl_parquet(conn, "abfss://container@account/data/*.parquet") |>
#'   dplyr::collect()
#' }
#' @export
tbl_parquet <- function(
  conn,
  url,
  name = NULL,
  hive_partitioning = FALSE,
  replace = TRUE
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  rlang::check_installed(c("dplyr", "dbplyr"))
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!is.null(name) && !rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar or {.code NULL}.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(hive_partitioning)) {
    abort_bad_arg(
      "{.arg hive_partitioning} must be `TRUE` or `FALSE`.",
      arg = "hive_partitioning",
      value = hive_partitioning
    )
  }
  out <- if (is.null(name)) {
    url <- check_azure_url(url)
    ensure_azure_exts(conn, delta = FALSE)
    dplyr::tbl(conn, dplyr::sql(sql_parquet_scan(url, hive_partitioning, conn)))
  } else {
    load_parquet(
      conn,
      url,
      name,
      hive_partitioning = hive_partitioning,
      replace = replace
    )
    dplyr::tbl(conn, name)
  }
  new_tbl_az(out)
}

#' Open a CSV dataset as a lazy dplyr tbl
#'
#' Validates the URL, loads the `azure` extension, then returns a lazy
#' [dplyr::tbl()] over the dataset. Use [az_conn()] first if the connection
#' needs Azure extensions, settings, or secrets.
#'
#' When `name` is `NULL` the dataset is queried directly via `read_csv_auto()`
#' with no persistent object registered on the connection. When `name` is
#' supplied the dataset is first registered as a VIEW via [load_csv()], then
#' referenced by name.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns.
#' @param name Optional character scalar. Name to register the view under in
#'   DuckDB. When `NULL` (default) the dataset is scanned directly.
#' @param replace Logical. Replace an existing view of the same name.
#'   Default `TRUE`. Ignored when `name = NULL`.
#' @param ... Reader options forwarded to DuckDB's `read_csv_auto()`.
#' @return A [dplyr::tbl()] backed by the CSV dataset.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' tbl_csv(conn, "abfss://container@account/data/*.csv") |>
#'   dplyr::collect()
#' }
#' @export
tbl_csv <- function(
  conn,
  url,
  name = NULL,
  replace = TRUE,
  ...
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  rlang::check_installed(c("dplyr", "dbplyr"))
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!is.null(name) && !rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar or {.code NULL}.",
      arg = "name",
      value = name
    )
  }
  options <- list(...)
  check_reader_options(options)
  out <- if (is.null(name)) {
    url <- check_azure_url(url)
    ensure_azure_exts(conn, delta = FALSE)
    dplyr::tbl(conn, dplyr::sql(sql_csv_scan(url, conn, options)))
  } else {
    load_csv(conn, url, name, replace = replace, ...)
    dplyr::tbl(conn, name)
  }
  new_tbl_az(out)
}

#' Open a JSON dataset as a lazy dplyr tbl
#'
#' Validates the URL, loads the `azure` extension, then returns a lazy
#' [dplyr::tbl()] over the dataset. Use [az_conn()] first if the connection
#' needs Azure extensions, settings, or secrets.
#'
#' When `name` is `NULL` the dataset is queried directly via `read_json_auto()`
#' with no persistent object registered on the connection. When `name` is
#' supplied the dataset is first registered as a VIEW via [load_json()], then
#' referenced by name.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns.
#' @param name Optional character scalar. Name to register the view under in
#'   DuckDB. When `NULL` (default) the dataset is scanned directly.
#' @param replace Logical. Replace an existing view of the same name.
#'   Default `TRUE`. Ignored when `name = NULL`.
#' @param ... Reader options forwarded to DuckDB's `read_json_auto()`.
#' @return A [dplyr::tbl()] backed by the JSON dataset.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' tbl_json(conn, "abfss://container@account/data/*.json") |>
#'   dplyr::collect()
#' }
#' @export
tbl_json <- function(
  conn,
  url,
  name = NULL,
  replace = TRUE,
  ...
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  rlang::check_installed(c("dplyr", "dbplyr"))
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!is.null(name) && !rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar or {.code NULL}.",
      arg = "name",
      value = name
    )
  }
  options <- list(...)
  check_reader_options(options)
  out <- if (is.null(name)) {
    url <- check_azure_url(url)
    ext_load("json", conn = conn, auto_install = TRUE, ask = FALSE)
    ensure_azure_exts(conn, delta = FALSE)
    dplyr::tbl(conn, dplyr::sql(sql_json_scan(url, conn, options)))
  } else {
    load_json(conn, url, name, replace = replace, ...)
    dplyr::tbl(conn, name)
  }
  new_tbl_az(out)
}

# tbl_az ----------------------------------------------------------------------

#' Tag a lazy tbl as Azure-backed
#'
#' Prepends the `tbl_az` S3 class to a lazy [dplyr::tbl()] so that
#' [collect.tbl_az()] can run pre-flight checks before the query is
#' materialised.
#'
#' @param x A lazy [dplyr::tbl()].
#' @return `x` with `"tbl_az"` prepended to its class vector.
#' @keywords internal
new_tbl_az <- function(x) {
  class(x) <- c("tbl_az", class(x))
  x
}

#' Collect an Azure-backed lazy tbl
#'
#' [dplyr::collect()] method for tables created by [tbl_delta()] and
#' [tbl_parquet()]. Verifies that the backing DuckDB connection is still open
#' and that the `azure` extension is loaded before the query is materialised,
#' then defers to the underlying dbplyr method.
#'
#' @param x A `tbl_az` produced by [tbl_delta()] or [tbl_parquet()].
#' @param ... Passed on to the next `collect()` method.
#' @return A [tibble::tibble()] with the collected rows.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' tbl_delta(conn, "abfss://container@account/path/sales") |>
#'   dplyr::collect()
#' }
#' @exportS3Method dplyr::collect
collect.tbl_az <- function(x, ...) {
  check_tbl_az(x)
  verbose <- opts$get("collect_verbose")
  if (verbose) {
    cli::cli_inform(c("i" = "Collecting data from Azure..."))
  }
  start <- proc.time()[["elapsed"]]
  class(x) <- setdiff(class(x), "tbl_az")
  result <- NextMethod()
  elapsed <- proc.time()[["elapsed"]] - start
  if (verbose) {
    cli::cli_inform(
      c(
        "v" = "Done. {nrow(result)} row{?s} collected in {collect_elapsed(elapsed)}."
      )
    )
  }
  result
}

collect_elapsed <- function(seconds) {
  if (!is.finite(seconds) || seconds < 0) {
    seconds <- 0
  }

  if (seconds < 1) {
    return(sprintf("%.0f ms", seconds * 1000))
  }
  if (seconds < 60) {
    return(sprintf("%.1f s", seconds))
  }

  minutes <- floor(seconds / 60)
  sprintf("%d min %.1f s", minutes, seconds - (minutes * 60))
}

temp_relation_name <- function(prefix) {
  suffix <- paste(sample(c(letters, 0:9), 10L, replace = TRUE), collapse = "")
  paste0(prefix, "_", suffix)
}

#' Pre-flight checks before collecting a `tbl_az`
#'
#' Aborts when the backing DuckDB connection is closed or the `azure` extension
#' is not loaded, turning otherwise cryptic collect-time failures into
#' actionable messages.
#'
#' @param x A `tbl_az`.
#' @param call The calling environment, used for error reporting.
#' @return Invisibly returns `x`.
#' @keywords internal
check_tbl_az <- function(x, call = rlang::caller_env()) {
  conn <- dbplyr::remote_con(x)
  if (is.null(conn) || !DBI::dbIsValid(conn)) {
    abort_conn_closed(call = call)
  }
  if (!ext_is_loaded("azure", conn)) {
    abort_ext_not_loaded("azure", call = call)
  }
  invisible(x)
}
