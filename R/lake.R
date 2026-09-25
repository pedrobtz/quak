#' Copy data to Azure Data Lake Storage Gen2
#'
#' Writes a lazy table, data frame, or SQL query to an `abfs://` or
#' `abfss://` URL using DuckDB's `COPY ... TO` command.
#'
#' @param conn A DuckDB connection.
#' @param x A lazy `dbplyr` table, data frame, SQL string, or `DBI::SQL`
#'   object.
#' @param url Character scalar. Azure Blob URL to write to.
#' @param format Output format. One of `"parquet"`, `"csv"`, or `"json"`.
#' @param partition_by Optional character vector of columns to partition by.
#' @param overwrite Logical. When `TRUE`, passes DuckDB's
#'   `OVERWRITE_OR_IGNORE` copy option.
#' @return Invisibly returns `url`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_copy_to(
#'   conn,
#'   "SELECT * FROM events WHERE event_date >= DATE '2026-01-01'",
#'   "abfss://container@account/exports/events",
#'   format = "parquet"
#' )
#' }
#' @export
az_copy_to <- function(
  conn,
  x,
  url,
  format = c("parquet", "csv", "json"),
  partition_by = NULL,
  overwrite = FALSE
) {
  check_required_arg(conn, "conn")
  check_required_arg(x, "x")
  check_required_arg(url, "url")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  format <- rlang::arg_match(format)
  check_partition_by(partition_by)
  if (!rlang::is_bool(overwrite)) {
    abort_bad_arg(
      "{.arg overwrite} must be `TRUE` or `FALSE`.",
      arg = "overwrite",
      value = overwrite
    )
  }

  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = FALSE)

  source <- tryCatch(
    az_copy_source_sql(conn, x),
    error = function(e) {
      if (inherits(e, "quak_error_bad_argument")) {
        stop(e)
      }
      abort_az_copy_failed(url, format, e)
    }
  )
  if (!is.null(source$cleanup)) {
    on.exit(try(source$cleanup(), silent = TRUE), add = TRUE)
  }

  tryCatch(
    DBI::dbExecute(
      conn,
      sql_copy_to(
        source$sql,
        url,
        format = format,
        partition_by = partition_by,
        overwrite = overwrite,
        conn = conn
      )
    ),
    error = function(e) {
      abort_az_copy_failed(url, format, e)
    }
  )

  invisible(url)
}

#' Write Parquet data to Azure Data Lake Storage Gen2
#'
#' Thin convenience wrapper around [az_copy_to()] with
#' `format = "parquet"`.
#'
#' @inheritParams az_copy_to
#' @return Invisibly returns `url`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_write_parquet(conn, data.frame(x = 1:3), "abfss://container@account/x")
#' }
#' @export
az_write_parquet <- function(
  conn,
  x,
  url,
  partition_by = NULL,
  overwrite = FALSE
) {
  az_copy_to(
    conn,
    x,
    url,
    format = "parquet",
    partition_by = partition_by,
    overwrite = overwrite
  )
}

#' List Azure paths matching a glob pattern
#'
#' Uses DuckDB's `glob()` table function over Azure storage.
#'
#' @param conn A DuckDB connection.
#' @param pattern Character scalar. `abfs://` or `abfss://` glob pattern.
#' @return Character vector of matching paths.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_glob(conn, "abfss://container@account/data/*.parquet")
#' }
#' @export
az_glob <- function(conn, pattern) {
  check_required_arg(conn, "conn")
  check_required_arg(pattern, "pattern")
  if (!rlang::is_string(pattern)) {
    abort_bad_arg(
      "{.arg pattern} must be a character scalar.",
      arg = "pattern",
      value = pattern
    )
  }
  pattern <- check_azure_url(pattern)
  ensure_azure_exts(conn, delta = FALSE)
  rows <- az_query(
    conn,
    sql_glob(pattern, conn),
    pattern,
    "Failed to list Azure paths matching {.val {url}}."
  )
  rows$file
}

#' Check whether data exists at an Azure path
#'
#' For an exact file or glob pattern, checks whether DuckDB's `glob()` returns
#' at least one match. For a plain path, also probes `url/**` so dataset
#' prefixes count as existing when they contain at least one object.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL or glob pattern.
#' @return Logical scalar.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_exists(conn, "abfss://container@account/data/sales")
#' }
#' @export
az_exists <- function(conn, url) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = FALSE)

  if (has_glob_pattern(url)) {
    return(az_glob_has_match(conn, url))
  }

  az_glob_has_match(conn, url) ||
    az_glob_has_match(conn, child_glob_pattern(url)) ||
    az_glob_has_match(conn, recursive_glob_pattern(url))
}

#' Inspect a dataset schema without collecting data
#'
#' Uses DuckDB's `DESCRIBE SELECT` over a remote scan and returns only column
#' names and DuckDB types.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL.
#' @param format Optional format override. One of `"parquet"`, `"csv"`,
#'   `"json"`, or `"delta"`. When `NULL`, inferred from `url`.
#' @return A tibble-like data frame with columns `name` and `type`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_schema(conn, "abfss://container@account/data/*.parquet")
#' }
#' @export
az_schema <- function(conn, url, format = NULL) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  url <- check_azure_url(url)
  format <- az_resolve_format(url, format)
  ensure_azure_exts(conn, delta = format == "delta")

  rows <- az_query(
    conn,
    sql_schema_query(url, format, conn),
    url,
    "Failed to inspect schema for Azure dataset {.val {url}}."
  )
  out <- data.frame(
    name = rows$column_name,
    type = rows$column_type,
    stringsAsFactors = FALSE
  )
  try_as_tibble(out)
}

#' Preview an Azure dataset
#'
#' Prints a small preview and invisibly returns it as a tibble-like data frame.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL.
#' @param n Number of rows to preview. Default `10`.
#' @param format Optional format override. One of `"parquet"`, `"csv"`,
#'   `"json"`, or `"delta"`. When `NULL`, inferred from `url`.
#' @return Invisibly returns the preview tibble-like data frame.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_glimpse(conn, "abfss://container@account/data/*.parquet", n = 5)
#' }
#' @export
az_glimpse <- function(conn, url, n = 10, format = NULL) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  if (!is_whole_number(n)) {
    abort_bad_arg(
      "{.arg n} must be a non-negative whole number.",
      arg = "n",
      value = n
    )
  }
  url <- check_azure_url(url)
  format <- az_resolve_format(url, format)
  ensure_azure_exts(conn, delta = format == "delta")

  out <- try_as_tibble(az_query(
    conn,
    sql_preview_query(
      url,
      format,
      n,
      conn
    ),
    url,
    "Failed to preview Azure dataset {.val {url}}."
  ))
  print(out)
  invisible(out)
}

sql_copy_to <- function(
  source_sql,
  url,
  format,
  partition_by = NULL,
  overwrite = FALSE,
  conn
) {
  options <- sql_copy_options(format, partition_by, overwrite, conn)
  glue::glue_sql(
    "COPY ({DBI::SQL(source_sql)}) TO {url} ({DBI::SQL(options)})",
    .con = conn
  )
}

sql_copy_options <- function(
  format,
  partition_by = NULL,
  overwrite = FALSE,
  conn
) {
  pieces <- list(glue::glue_sql("FORMAT {DBI::SQL(format)}", .con = conn))
  if (!is.null(partition_by)) {
    pieces[[length(pieces) + 1L]] <- glue::glue_sql(
      "PARTITION_BY ({`partition_by`*})",
      .con = conn
    )
  }
  if (overwrite) {
    pieces[[length(pieces) + 1L]] <- DBI::SQL("OVERWRITE_OR_IGNORE true")
  }
  DBI::SQL(paste(vapply(pieces, as.character, character(1)), collapse = ", "))
}

sql_glob <- function(pattern, conn, limit = NULL) {
  limit_sql <- if (is.null(limit)) {
    DBI::SQL("")
  } else {
    glue::glue_sql(" LIMIT {limit}", .con = conn)
  }
  glue::glue_sql(
    "SELECT file FROM glob({pattern}){limit_sql}",
    .con = conn
  )
}

sql_schema_query <- function(url, format, conn) {
  glue::glue_sql(
    "DESCRIBE {DBI::SQL(sql_select_all(url, format, conn))}",
    .con = conn
  )
}

sql_preview_query <- function(url, format, n, conn) {
  glue::glue_sql(
    "{DBI::SQL(sql_select_all(url, format, conn))} LIMIT {n}",
    .con = conn
  )
}

sql_select_all <- function(url, format, conn) {
  glue::glue_sql(
    "SELECT * FROM {DBI::SQL(sql_scan_source(url, format, conn))}",
    .con = conn
  )
}

sql_scan_source <- function(url, format, conn) {
  switch(
    format,
    parquet = glue::glue_sql(
      "read_parquet({url}, union_by_name = true)",
      .con = conn
    ),
    csv = sql_csv_source(url, conn),
    json = sql_json_source(url, conn),
    delta = glue::glue_sql("delta_scan({url})", .con = conn)
  )
}


az_copy_source_sql <- function(conn, x) {
  if (inherits(x, "SQL")) {
    return(list(sql = as.character(x), cleanup = NULL))
  }
  if (rlang::is_string(x)) {
    return(list(sql = x, cleanup = NULL))
  }
  if (is.data.frame(x)) {
    name <- temp_relation_name("quak_copy")
    DBI::dbWriteTable(conn, name, x, temporary = TRUE)
    cleanup <- function() {
      DBI::dbExecute(
        conn,
        glue::glue_sql("DROP TABLE IF EXISTS {`name`}", .con = conn)
      )
    }
    sql <- glue::glue_sql("SELECT * FROM {`name`}", .con = conn)
    return(list(sql = as.character(sql), cleanup = cleanup))
  }
  if (inherits(x, "tbl_sql") || inherits(x, "tbl_lazy")) {
    rlang::check_installed("dbplyr")
    if (!identical(dbplyr::remote_con(x), conn)) {
      abort_bad_arg(
        c(
          "{.arg x} is a lazy table from a different connection than {.arg conn}.",
          "i" = "Pass a table built on {.arg conn}, or materialise it first with {.fn dplyr::collect}."
        ),
        arg = "x",
        value = x
      )
    }
    return(list(sql = as.character(dbplyr::sql_render(x)), cleanup = NULL))
  }

  abort_bad_arg(
    "{.arg x} must be a lazy table, data frame, SQL string, or {.code DBI::SQL} object.",
    arg = "x",
    value = x
  )
}

az_glob_has_match <- function(conn, pattern) {
  rows <- az_query(
    conn,
    sql_glob(pattern, conn, limit = 1L),
    pattern,
    "Failed to check whether Azure path {.val {url}} exists."
  )
  nrow(rows) > 0L
}

az_query <- function(conn, sql, url, message) {
  tryCatch(
    DBI::dbGetQuery(conn, sql),
    error = function(e) {
      abort_az_query_failed(message, url, e)
    }
  )
}

has_glob_pattern <- function(url) {
  grepl("[*?\\[]", url)
}

recursive_glob_pattern <- function(url) {
  url <- gsub("\\\\", "/", url)
  paste0(sub("/+$", "", url), "/**")
}

child_glob_pattern <- function(url) {
  url <- gsub("\\\\", "/", url)
  paste0(sub("/+$", "", url), "/*")
}

check_partition_by <- function(partition_by, call = rlang::caller_env()) {
  if (is.null(partition_by)) {
    return(invisible(NULL))
  }
  if (
    !is.character(partition_by) ||
      length(partition_by) == 0L ||
      anyNA(partition_by) ||
      !all(nzchar(partition_by))
  ) {
    abort_bad_arg(
      "{.arg partition_by} must be a non-empty character vector or {.code NULL}.",
      arg = "partition_by",
      value = partition_by,
      call = call
    )
  }
  invisible(NULL)
}

az_resolve_format <- function(url, format = NULL, call = rlang::caller_env()) {
  choices <- c("parquet", "csv", "json", "delta")
  if (!is.null(format)) {
    return(rlang::arg_match(format, choices))
  }

  path <- sub("[?#].*$", "", url)
  ext <- tolower(tools::file_ext(path))
  inferred <- switch(
    ext,
    parquet = "parquet",
    csv = "csv",
    json = "json",
    jsonl = "json",
    ndjson = "json",
    NULL
  )
  if (is.null(inferred)) {
    abort_bad_arg(
      c(
        "Cannot infer dataset format from {.arg url}.",
        "i" = "Supply {.arg format} as one of {.val {choices}}."
      ),
      arg = "format",
      url = url,
      valid = choices,
      call = call
    )
  }
  inferred
}
