#' Create a DuckDB driver
#'
#' Thin wrapper around [duckdb::duckdb()] with quak-friendly defaults.
#'
#' @param dbdir Character scalar. Database path. Defaults to `":memory:"`.
#' @param read_only Logical. Open in read-only mode. Defaults to `FALSE`.
#' @param bigint Character scalar. How to represent 64-bit integers.
#'   Defaults to `"numeric"`.
#' @param config Named list of DuckDB configuration options. Defaults to
#'   `list()`.
#' @param ... Additional arguments passed to [duckdb::duckdb()].
#' @param unsigned Logical. Allow loading unsigned (locally-built or
#'   community) extensions — equivalent to `duckdb -unsigned` on the CLI.
#'   Sets `allow_unsigned_extensions = "true"` in `config`. Defaults to
#'   `FALSE`.
#' @param environment_scan Logical. Scan the R environment for secrets.
#'   Defaults to `FALSE`.
#' @return A `duckdb_driver` object.
#' @keywords internal
conn_driver <- function(
  dbdir = ":memory:",
  read_only = FALSE,
  bigint = "numeric",
  config = list(),
  ...,
  unsigned = FALSE,
  environment_scan = FALSE
) {
  if (unsigned) {
    config[["allow_unsigned_extensions"]] <- "true"
  }
  duckdb::duckdb(
    dbdir = dbdir,
    read_only = read_only,
    bigint = bigint,
    config = config,
    ...,
    environment_scan = environment_scan
  )
}

#' Default DuckDB connection
#'
#' Returns the DuckDB default connection (thin wrapper around
#' [duckdb::default_conn()]).
#'
#' @return A DuckDB connection.
#' @keywords internal
conn_default <- function() {
  duckdb::default_conn()
}


#' Create a DuckDB connection
#'
#' Thin wrapper around [DBI::dbConnect()] with quak-friendly defaults.
#'
#' @param ... Additional arguments passed to [DBI::dbConnect()].
#' @param drv A DuckDB driver. Defaults to [conn_driver()].
#' @param timezone_out Character scalar. Timezone for `TIMESTAMPTZ` output.
#'   Defaults to `""` (UTC).
#' @param array Character scalar. How to represent DuckDB arrays.
#'   Defaults to `"matrix"`.
#' @return A `duckdb_connection` object.
#' @keywords internal
conn_open <- function(
  ...,
  drv = conn_driver(),
  timezone_out = "",
  array = "matrix"
) {
  DBI::dbConnect(drv = drv, ..., timezone_out = timezone_out, array = array)
}

#' DuckDB instance info
#'
#' Queries the active connection for the library version and platform string.
#' The two values together identify the subdirectory path used by the extension
#' repositories, e.g. `v1.2.0/osx_arm64/`.
#'
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return A named list with elements `version` (e.g. `"v1.2.0"`) and
#'   `platform` (e.g. `"osx_arm64"`).
#' @keywords internal
conn_info <- function(conn = conn_default()) {
  row <- DBI::dbGetQuery(
    conn,
    "SELECT version() AS version, platform FROM pragma_platform()"
  )
  list(version = row$version, platform = row$platform)
}


#' Get or set DuckDB settings
#'
#' When called with no arguments, returns all settings as a data frame. When `name`
#' is supplied and `value` is `NULL`, returns the value of that setting. When
#' both `name` and `value` are supplied, executes `SET <name> = <value>`.
#'
#' @param conn A DuckDB connection.
#' @param name Optional character scalar. Setting name.
#' @param value Optional value to set. Coerced to character; DuckDB casts it to
#'   the appropriate type.
#' @return All settings: a [tibble::tibble()]. Single setting read: a
#'   character scalar. Write: `conn` invisibly.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' conn_setting(conn, "threads")
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
conn_setting <- function(
  conn = conn_default(),
  name = NULL,
  value = NULL
) {
  if (!is.null(name) && !rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar or {.code NULL}.",
      arg = "name",
      value = name
    )
  }

  if (is.null(name)) {
    return(try_as_tibble(DBI::dbGetQuery(
      conn,
      "SELECT * FROM duckdb_settings()"
    )))
  }

  if (is.null(value)) {
    rows <- DBI::dbGetQuery(
      conn,
      glue::glue_sql(
        "SELECT value FROM duckdb_settings() WHERE name = {name}",
        .con = conn
      )
    )
    if (nrow(rows) == 0L) {
      warn_unknown_setting(name)
      return(invisible(NULL))
    }
    return(rows$value[[1L]])
  }

  if (!grepl("^[A-Za-z_][A-Za-z0-9_]*$", name)) {
    abort_bad_arg(
      "{.arg name} must contain only letters, digits, and underscores.",
      arg = "name",
      value = name
    )
  }

  DBI::dbExecute(
    conn,
    glue::glue_sql("SET {DBI::SQL(name)} = {value}", .con = conn)
  )
  cli::cli_inform(c("v" = "Set {.code {name}} = {.val {value}}"))
  invisible(conn)
}

#' Tune Azure read settings on a DuckDB connection
#'
#' Sets the Azure performance and transport settings exposed by DuckDB. Each
#' argument defaults to `NULL`, which leaves that setting unchanged.
#'
#' @param conn A DuckDB connection.
#' @param concurrency Optional positive whole number for
#'   `azure_read_transfer_concurrency`.
#' @param chunk_size Optional positive whole number or character scalar for
#'   `azure_read_transfer_chunk_size`.
#' @param buffer_size Optional positive whole number or character scalar for
#'   `azure_read_buffer_size`.
#' @param transport Optional character scalar for
#'   `azure_transport_option_type`.
#' @param metadata_cache Optional logical scalar for
#'   `enable_http_metadata_cache`.
#' @param context_cache Optional logical scalar for `azure_context_caching`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_tune(conn, concurrency = 8, metadata_cache = TRUE)
#' }
#' @export
az_tune <- function(
  conn,
  concurrency = NULL,
  chunk_size = NULL,
  buffer_size = NULL,
  transport = NULL,
  metadata_cache = NULL,
  context_cache = NULL
) {
  check_required_arg(conn, "conn")
  az_check_positive_whole(concurrency, "concurrency")
  az_check_size_setting(chunk_size, "chunk_size")
  az_check_size_setting(buffer_size, "buffer_size")
  if (!is.null(transport) && !rlang::is_string(transport)) {
    abort_bad_arg(
      "{.arg transport} must be a character scalar or {.code NULL}.",
      arg = "transport",
      value = transport
    )
  }
  az_check_bool_setting(metadata_cache, "metadata_cache")
  az_check_bool_setting(context_cache, "context_cache")

  ensure_azure_exts(conn, delta = FALSE)

  if (!is.null(buffer_size)) {
    effective_chunk <- if (is.null(chunk_size)) {
      suppressWarnings(as.numeric(az_get_tune_setting(
        conn,
        "azure_read_transfer_chunk_size"
      )))
    } else {
      suppressWarnings(as.numeric(chunk_size))
    }
    effective_buffer <- suppressWarnings(as.numeric(buffer_size))
    if (
      length(effective_chunk) == 1L &&
        length(effective_buffer) == 1L &&
        is.finite(effective_chunk) &&
        is.finite(effective_buffer) &&
        effective_chunk > 0 &&
        effective_buffer %% effective_chunk != 0
    ) {
      warn_az_buffer_not_multiple(buffer_size, effective_chunk)
    }
  }

  az_set_tune_setting(conn, "azure_read_transfer_concurrency", concurrency)
  az_set_tune_setting(conn, "azure_read_transfer_chunk_size", chunk_size)
  az_set_tune_setting(conn, "azure_read_buffer_size", buffer_size)
  az_set_tune_setting(conn, "azure_transport_option_type", transport)
  az_set_tune_setting(conn, "enable_http_metadata_cache", metadata_cache)
  az_set_tune_setting(conn, "azure_context_caching", context_cache)

  invisible(conn)
}

try_as_tibble <- function(x) {
  if (rlang::is_installed("tibble")) tibble::as_tibble(x) else x
}

az_set_tune_setting <- function(conn, name, value) {
  if (is.null(value)) {
    return(invisible(conn))
  }
  tryCatch(
    DBI::dbExecute(
      conn,
      glue::glue_sql("SET {DBI::SQL(name)} = {value}", .con = conn)
    ),
    error = function(e) {
      abort_az_tune_failed(name, value, e)
    }
  )
  invisible(conn)
}

az_get_tune_setting <- function(conn, name) {
  rows <- tryCatch(
    DBI::dbGetQuery(
      conn,
      glue::glue_sql(
        "SELECT value FROM duckdb_settings() WHERE name = {name}",
        .con = conn
      )
    ),
    error = function(e) {
      abort_az_tune_failed(name, NULL, e)
    }
  )
  if (nrow(rows) == 0L) {
    warn_unknown_setting(name)
    return(invisible(NULL))
  }
  rows$value[[1L]]
}

az_check_positive_whole <- function(value, arg) {
  if (is.null(value)) {
    return(invisible(NULL))
  }
  if (!is_whole_number(value) || value <= 0) {
    abort_bad_arg(
      "{.arg {arg}} must be a positive whole number or {.code NULL}.",
      arg = arg,
      value = value
    )
  }
  invisible(NULL)
}

az_check_size_setting <- function(value, arg) {
  if (is.null(value)) {
    return(invisible(NULL))
  }
  ok <- (rlang::is_string(value) && nzchar(value)) ||
    (is.numeric(value) && length(value) == 1L && is.finite(value) && value > 0)
  if (!ok) {
    abort_bad_arg(
      "{.arg {arg}} must be a positive number, character scalar, or {.code NULL}.",
      arg = arg,
      value = value
    )
  }
  invisible(NULL)
}

az_check_bool_setting <- function(value, arg) {
  if (is.null(value)) {
    return(invisible(NULL))
  }
  if (!rlang::is_bool(value)) {
    abort_bad_arg(
      "{.arg {arg}} must be `TRUE`, `FALSE`, or {.code NULL}.",
      arg = arg,
      value = value
    )
  }
  invisible(NULL)
}
