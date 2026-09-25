# Registered datasets ---------------------------------------------------------

#' Register a Delta Lake table on a DuckDB connection
#'
#' Validates the URL, loads the `azure` and `delta` extensions, then registers
#' the table either as an ATTACH database or a VIEW. Use [az_conn()] first if
#' the connection needs an Azure secret. Returns `conn` invisibly — use
#' [tbl_delta()] if you want a `dplyr::tbl()`.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL pointing to a Delta table.
#' @param name Character scalar. Name to register the table under in DuckDB.
#' @param method `"attach"` (default) or `"view"`.
#' @param replace Logical. Replace an existing registration. Default `TRUE`.
#' @param version Optional non-negative Delta table version to attach.
#' @param timestamp Deprecated. Not supported: DuckDB's `delta` extension
#'   accepts a `TIMESTAMP` attach option but ignores it, returning the latest
#'   snapshot. Supplying it raises an error. Use `version` instead.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' load_delta(conn, "abfss://container@account/path/sales", name = "sales")
#' DBI::dbGetQuery(conn, "SELECT COUNT(*) FROM sales")
#' }
#' @export
load_delta <- function(
  conn,
  url,
  name,
  method = c("attach", "view"),
  replace = TRUE,
  version = NULL,
  timestamp = NULL
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  check_required_arg(name, "name")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(replace)) {
    abort_bad_arg(
      "{.arg replace} must be `TRUE` or `FALSE`.",
      arg = "replace",
      value = replace
    )
  }
  check_delta_time_travel(version, timestamp)
  method <- rlang::arg_match(method)
  if (method == "view" && !is.null(version)) {
    abort_bad_arg(
      "{.arg version} is only supported with {.code method = 'attach'}.",
      arg = "method",
      value = method
    )
  }
  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = TRUE)
  sql <- switch(
    method,
    attach = sql_delta_attach(
      url,
      name,
      replace,
      conn,
      version = version,
      timestamp = timestamp
    ),
    view = sql_delta_view(url, name, replace, conn)
  )
  tryCatch(
    DBI::dbExecute(conn, sql),
    error = function(e) {
      abort_register_delta(name, url, e)
    }
  )
  cli::cli_inform("Delta table {.val {name}} registered ({method}).")
  invisible(conn)
}

#' Register a Parquet dataset as a view on a DuckDB connection
#'
#' Validates the URL, loads the `azure` extension, then registers the dataset
#' as a VIEW. Use [az_conn()] first if the connection needs an Azure secret.
#' Returns `conn` invisibly — use [tbl_parquet()] if you want a `dplyr::tbl()`.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns.
#' @param name Character scalar. Name to register the view under in DuckDB.
#' @param hive_partitioning Logical. Enable Hive partition inference. Default `FALSE`.
#' @param replace Logical. Replace an existing view. Default `TRUE`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' load_parquet(conn, "abfss://container@account/data/*.parquet", name = "events")
#' }
#' @export
load_parquet <- function(
  conn,
  url,
  name,
  hive_partitioning = FALSE,
  replace = TRUE
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  check_required_arg(name, "name")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
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
  if (!rlang::is_bool(replace)) {
    abort_bad_arg(
      "{.arg replace} must be `TRUE` or `FALSE`.",
      arg = "replace",
      value = replace
    )
  }
  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = FALSE)
  tryCatch(
    DBI::dbExecute(
      conn,
      sql_parquet_view(url, name, hive_partitioning, replace, conn)
    ),
    error = function(e) {
      abort_register_parquet(name, url, e)
    }
  )
  cli::cli_inform("Parquet dataset {.val {name}} registered as view.")
  invisible(conn)
}

#' Register a CSV dataset as a view on a DuckDB connection
#'
#' Validates the URL, loads the `azure` extension, then registers the dataset
#' as a VIEW over `read_csv_auto()`. Use [az_conn()] first if the connection
#' needs an Azure secret. Returns `conn` invisibly — use [tbl_csv()] if you
#' want a `dplyr::tbl()`.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns.
#' @param name Character scalar. Name to register the view under in DuckDB.
#' @param replace Logical. Replace an existing view. Default `TRUE`.
#' @param ... Reader options forwarded to DuckDB's `read_csv_auto()`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' load_csv(conn, "abfss://container@account/data/*.csv", name = "events")
#' }
#' @export
load_csv <- function(
  conn,
  url,
  name,
  replace = TRUE,
  ...
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  check_required_arg(name, "name")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(replace)) {
    abort_bad_arg(
      "{.arg replace} must be `TRUE` or `FALSE`.",
      arg = "replace",
      value = replace
    )
  }
  options <- list(...)
  check_reader_options(options)
  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = FALSE)
  tryCatch(
    DBI::dbExecute(conn, sql_csv_view(url, name, replace, conn, options)),
    error = function(e) {
      abort_register_csv(name, url, e)
    }
  )
  cli::cli_inform("CSV dataset {.val {name}} registered as view.")
  invisible(conn)
}

#' Register a JSON dataset as a view on a DuckDB connection
#'
#' Validates the URL, loads the `azure` extension, then registers the dataset
#' as a VIEW over `read_json_auto()`. Use [az_conn()] first if the connection
#' needs an Azure secret. Returns `conn` invisibly — use [tbl_json()] if you
#' want a `dplyr::tbl()`.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL. Supports glob patterns.
#' @param name Character scalar. Name to register the view under in DuckDB.
#' @param replace Logical. Replace an existing view. Default `TRUE`.
#' @param ... Reader options forwarded to DuckDB's `read_json_auto()`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' load_json(conn, "abfss://container@account/data/*.json", name = "events")
#' }
#' @export
load_json <- function(
  conn,
  url,
  name,
  replace = TRUE,
  ...
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  check_required_arg(name, "name")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(replace)) {
    abort_bad_arg(
      "{.arg replace} must be `TRUE` or `FALSE`.",
      arg = "replace",
      value = replace
    )
  }
  options <- list(...)
  check_reader_options(options)
  url <- check_azure_url(url)
  ext_load("json", conn = conn, auto_install = TRUE, ask = FALSE)
  ensure_azure_exts(conn, delta = FALSE)
  tryCatch(
    DBI::dbExecute(conn, sql_json_view(url, name, replace, conn, options)),
    error = function(e) {
      abort_register_json(name, url, e)
    }
  )
  cli::cli_inform("JSON dataset {.val {name}} registered as view.")
  invisible(conn)
}

#' Register a Delta, Parquet, CSV, or JSON dataset on a DuckDB connection
#'
#' Dispatches to [load_delta()], [load_parquet()], [load_csv()], or
#' [load_json()] based on `format`. Only arguments accepted by the target
#' function may be passed via `...`; passing `format`-incompatible arguments
#' raises an error.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL.
#' @param name Character scalar. Name to register the dataset under in DuckDB.
#' @param format One of `"delta"`, `"parquet"`, `"csv"`, or `"json"`.
#' @param ... Passed to the selected loader.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' load_dataset(
#'   conn,
#'   "abfss://container@account/path/sales",
#'   name = "sales",
#'   format = "delta"
#' )
#' }
#' @export
load_dataset <- function(
  conn,
  url,
  name,
  format = c("delta", "parquet", "csv", "json"),
  ...
) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  check_required_arg(name, "name")
  format <- rlang::arg_match(format)

  target <- switch(
    format,
    delta = load_delta,
    parquet = load_parquet,
    csv = load_csv,
    json = load_json
  )
  formal_names <- names(formals(target))
  allowed <- setdiff(formal_names, c("url", "name", "conn", "..."))
  extra <- setdiff(names(list(...)), allowed)
  # Loaders taking `...` forward reader options to DuckDB and validate them
  # themselves, so the explicit-formals allowlist only applies to the others.
  if (!("..." %in% formal_names) && length(extra) > 0L) {
    fn <- paste0("load_", format)
    abort_bad_arg(
      c(
        "{cli::qty(extra)}Argument{?s} {.arg {extra}} not accepted by {.fn {fn}}.",
        "i" = "Accepted via {.code ...}: {.arg {allowed}}."
      ),
      arg = extra,
      accepted = allowed,
      function_name = fn
    )
  }

  target(conn, url, name, ...)
}

# Helpers ---------------------------------------------------------------------

#' Validate and normalise an Azure Data Lake URL
#'
#' Aborts when `url` is not an `abfss://` URL, then rewrites the
#' `container@account` authority form to the account-host form DuckDB
#' documents. Always use the returned value rather than the input.
#'
#' @param url Character scalar. URL to validate.
#' @return The normalised URL.
#' @keywords internal
check_azure_url <- function(url) {
  if (!grepl("^abfss?://", url)) {
    abort_invalid_azure_url(url)
  }
  normalize_azure_url(url)
}

#' Rewrite `container@account` Azure URLs to the account-host form
#'
#' DuckDB's azure extension documents two ADLS URL forms:
#' `abfss://container/path` (account supplied by a secret) and
#' `abfss://account.dfs.core.windows.net/container/path`. The
#' `abfss://container@account/path` form is not one of them: without a
#' matching secret DuckDB rejects it with "Cannot identify the storage
#' account from path", and because the container precedes the account in the
#' string, no account-derived secret scope can ever match it.
#'
#' Rewriting it here means account-scoped secrets select correctly and the
#' URL is one DuckDB documents. URLs without an `@` in the authority are
#' returned unchanged.
#'
#' @param url Character scalar. An `abfss://` or `abfs://` URL.
#' @return The normalised URL.
#' @keywords internal
normalize_azure_url <- function(url) {
  parts <- regmatches(
    url,
    regexec("^(abfss?)://([^/@]+)@([^/]+)(/.*)?$", url)
  )[[1L]]
  if (length(parts) == 0L) {
    return(url)
  }
  scheme <- parts[2L]
  container <- parts[3L]
  account <- parts[4L]
  path <- parts[5L]
  if (!grepl(".", account, fixed = TRUE)) {
    account <- paste0(account, ".dfs.core.windows.net")
  }
  paste0(scheme, "://", account, "/", container, path)
}

#' Ensure Azure-related extensions are loaded
#'
#' Loads the `azure` extension and, optionally, the `delta` extension on
#' `conn`. Does not auto-install.
#'
#' @param conn A DuckDB connection.
#' @param delta Logical. Also load the `delta` extension.
#' @return Invisibly returns `NULL`; called for its side effect of loading the
#'   `azure` (and optionally `delta`) extension onto `conn`.
#' @keywords internal
ensure_azure_exts <- function(conn, delta = FALSE) {
  ext_load("azure", conn = conn, auto_install = FALSE, ask = FALSE)
  if (delta) {
    ext_load("delta", conn = conn, auto_install = FALSE, ask = FALSE)
  }
  invisible(NULL)
}

# SQL builders ----------------------------------------------------------------

sql_or_replace <- function(replace) if (replace) "OR REPLACE " else ""

sql_delta_attach <- function(
  url,
  name,
  replace = TRUE,
  conn = conn_default(),
  version = NULL,
  timestamp = NULL
) {
  time_travel <- sql_delta_time_travel(version, timestamp, conn)
  glue::glue_sql(
    "ATTACH {DBI::SQL(sql_or_replace(replace))}{url}
       AS {`name`}
      (TYPE DELTA{time_travel})",
    .con = conn
  )
}

sql_delta_scan <- function(url, conn) {
  glue::glue_sql("SELECT * FROM delta_scan({url})", .con = conn)
}

sql_parquet_scan <- function(url, hive_partitioning = FALSE, conn) {
  glue::glue_sql(
    "SELECT * FROM read_parquet({url}, hive_partitioning = {hive_partitioning}, union_by_name = true)",
    .con = conn
  )
}

sql_csv_scan <- function(url, conn, options = list()) {
  glue::glue_sql(
    "SELECT * FROM {DBI::SQL(sql_csv_source(url, conn, options))}",
    .con = conn
  )
}

sql_json_scan <- function(url, conn, options = list()) {
  glue::glue_sql(
    "SELECT * FROM {DBI::SQL(sql_json_source(url, conn, options))}",
    .con = conn
  )
}

sql_csv_source <- function(url, conn, options = list()) {
  sql_scan_call("read_csv_auto", url, conn, options)
}

sql_json_source <- function(url, conn, options = list()) {
  sql_scan_call("read_json_auto", url, conn, options)
}

sql_delta_view <- function(url, name, replace = TRUE, conn = conn_default()) {
  glue::glue_sql(
    "CREATE {DBI::SQL(sql_or_replace(replace))}VIEW {`name`} AS
       {DBI::SQL(sql_delta_scan(url, conn))}",
    .con = conn
  )
}

sql_parquet_view <- function(
  url,
  name,
  hive_partitioning = FALSE,
  replace = TRUE,
  conn = conn_default()
) {
  glue::glue_sql(
    "CREATE {DBI::SQL(sql_or_replace(replace))}VIEW {`name`} AS
     {DBI::SQL(sql_parquet_scan(url, hive_partitioning, conn))}",
    .con = conn
  )
}

sql_csv_view <- function(
  url,
  name,
  replace = TRUE,
  conn = conn_default(),
  options = list()
) {
  glue::glue_sql(
    "CREATE {DBI::SQL(sql_or_replace(replace))}VIEW {`name`} AS
       {DBI::SQL(sql_csv_scan(url, conn, options))}",
    .con = conn
  )
}

sql_json_view <- function(
  url,
  name,
  replace = TRUE,
  conn = conn_default(),
  options = list()
) {
  glue::glue_sql(
    "CREATE {DBI::SQL(sql_or_replace(replace))}VIEW {`name`} AS
       {DBI::SQL(sql_json_scan(url, conn, options))}",
    .con = conn
  )
}

sql_scan_call <- function(function_name, url, conn, options = list()) {
  option_sql <- as.character(sql_reader_options(options, conn))
  comma <- if (nzchar(option_sql)) ", " else ""
  glue::glue_sql(
    "{DBI::SQL(function_name)}({url}{DBI::SQL(comma)}{DBI::SQL(option_sql)})",
    .con = conn
  )
}

check_reader_options <- function(options, call = rlang::caller_env()) {
  if (length(options) == 0L) {
    return(invisible(NULL))
  }
  names <- names(options)
  if (is.null(names) || !all(nzchar(names))) {
    abort_bad_arg(
      "{.arg ...} reader options must be named.",
      arg = "...",
      call = call
    )
  }
  bad <- names[!grepl("^[A-Za-z_][A-Za-z0-9_]*$", names)]
  if (length(bad) > 0L) {
    abort_bad_arg(
      "{.arg ...} contains invalid reader option name{?s}: {.arg {bad}}.",
      arg = bad,
      call = call
    )
  }
  invisible(NULL)
}

sql_reader_options <- function(options, conn) {
  check_reader_options(options)
  if (length(options) == 0L) {
    return(DBI::SQL(""))
  }

  pieces <- Map(
    function(name, value) {
      if (is.null(value)) {
        return(NULL)
      }
      glue::glue_sql(
        "{DBI::SQL(name)} = {DBI::SQL(sql_literal(value, conn))}",
        .con = conn
      )
    },
    names(options),
    options
  )
  pieces <- pieces[!vapply(pieces, is.null, logical(1))]
  DBI::SQL(paste(vapply(pieces, as.character, character(1)), collapse = ", "))
}

sql_literal <- function(value, conn) {
  if (inherits(value, "SQL")) {
    return(value)
  }
  if (length(value) != 1L) {
    values <- vapply(value, sql_scalar_literal, character(1), conn = conn)
    return(DBI::SQL(paste0("[", paste(values, collapse = ", "), "]")))
  }
  sql_scalar_literal(value, conn)
}

sql_scalar_literal <- function(value, conn) {
  if (is.null(value)) {
    return(DBI::SQL("NULL"))
  }
  if (length(value) != 1L || is.na(value)) {
    abort_bad_arg(
      "SQL option values must be non-missing scalars or vectors.",
      arg = "..."
    )
  }
  if (is.logical(value)) {
    return(DBI::SQL(if (value) "true" else "false"))
  }
  glue::glue_sql("{value}", .con = conn)
}

check_delta_time_travel <- function(
  version = NULL,
  timestamp = NULL,
  call = rlang::caller_env()
) {
  if (!is.null(version) && !is.null(timestamp)) {
    abort_bad_arg(
      "Only one of {.arg version} or {.arg timestamp} may be supplied.",
      arg = "version",
      version = version,
      timestamp = timestamp,
      call = call
    )
  }
  if (!is.null(version) && !is_whole_number(version)) {
    abort_bad_arg(
      "{.arg version} must be a non-negative whole number or {.code NULL}.",
      arg = "version",
      value = version,
      call = call
    )
  }
  if (!is.null(timestamp) && !rlang::is_string(timestamp)) {
    abort_bad_arg(
      "{.arg timestamp} must be a character scalar or {.code NULL}.",
      arg = "timestamp",
      value = timestamp,
      call = call
    )
  }
  # DuckDB's delta extension accepts a TIMESTAMP option on ATTACH but ignores
  # it, returning the latest snapshot. It validates no ATTACH options at all,
  # so refusing here is the only way the caller learns the request was not met.
  if (!is.null(timestamp)) {
    abort_bad_arg(
      c(
        "{.arg timestamp} is not supported by DuckDB's {.pkg delta} extension.",
        "x" = "It accepts the option, ignores it, and returns the latest snapshot.",
        "i" = "Use {.arg version} to pin a Delta table version instead."
      ),
      arg = "timestamp",
      value = timestamp,
      call = call
    )
  }
  invisible(NULL)
}

sql_delta_time_travel <- function(version = NULL, timestamp = NULL, conn) {
  # Rejects `timestamp`; only `version` can reach the SQL below.
  check_delta_time_travel(version, timestamp)
  if (!is.null(version)) {
    return(glue::glue_sql(", VERSION {version}", .con = conn))
  }
  DBI::SQL("")
}

is_whole_number <- function(x) {
  is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x >= 0 &&
    x == floor(x)
}
