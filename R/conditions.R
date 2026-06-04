quak_abort <- function(
  message,
  class,
  ...,
  parent = NULL,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  fields <- list(...)
  cli_env <- list2env(fields, parent = .envir)
  rlang::exec(
    cli::cli_abort,
    message,
    class = c(class, "quak_error"),
    !!!fields,
    parent = parent,
    call = call,
    .envir = cli_env
  )
}

quak_warn <- function(
  message,
  class,
  ...,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  fields <- list(...)
  cli_env <- list2env(fields, parent = .envir)
  rlang::exec(
    cli::cli_warn,
    message,
    class = c(class, "quak_warning"),
    !!!fields,
    call = call,
    .envir = cli_env
  )
}

check_required_arg <- function(value, arg, call = rlang::caller_env()) {
  if (missing(value)) {
    abort_bad_arg("{.arg {arg}} is required.", arg = arg, call = call)
  }
  invisible(NULL)
}

abort_bad_arg <- function(
  message,
  arg = NULL,
  value = NULL,
  ...,
  call = rlang::caller_env()
) {
  fields <- list(arg = arg, value = value, ...)
  if (rlang::is_string(arg)) {
    fields[[arg]] <- value
  }
  fields$call <- call
  fields$.envir <- rlang::caller_env()

  rlang::exec(
    quak_abort,
    message,
    "quak_error_bad_argument",
    !!!fields
  )
}

abort_unknown_option <- function(name, valid, call = rlang::caller_env()) {
  quak_abort(
    "Unknown quak option {.val {name}}. Valid options: {.val {valid}}.",
    "quak_error_unknown_option",
    option = name,
    valid = valid,
    call = call
  )
}

abort_invalid_option <- function(
  name,
  envvar,
  valid = c("TRUE", "FALSE"),
  call = rlang::caller_env()
) {
  message <- if (identical(valid, c("TRUE", "FALSE"))) {
    "{.option quak.{name}} / {.envvar {envvar}} must be `TRUE` or `FALSE`."
  } else {
    "{.option quak.{name}} / {.envvar {envvar}} must be one of {.val {valid}}."
  }
  quak_abort(
    message,
    "quak_error_invalid_option",
    option = name,
    envvar = envvar,
    valid = valid,
    call = call
  )
}

abort_unknown_opt_type <- function(name, type, call = rlang::caller_env()) {
  quak_abort(
    "Unknown type {.val {type}} for quak option {.val {name}}.",
    "quak_error_invalid_option",
    option = name,
    type = type,
    call = call
  )
}

abort_repo_check_failed <- function(repo, failed, call = rlang::caller_env()) {
  label <- paste0(toupper(substr(repo, 1L, 1L)), substr(repo, 2L, nchar(repo)))
  quak_abort(
    "{label} repository check failed for: {failed}",
    "quak_error_repo_check_failed",
    repo = repo,
    failed = failed,
    call = call
  )
}

abort_repo_url_missing <- function(repo, envvar, call = rlang::caller_env()) {
  quak_abort(
    c(
      "No repository URL configured for {.val {repo}}.",
      "i" = "Set one with {.code repo_set_urls({repo} = 'https://...')} or the {.envvar {envvar}} env var."
    ),
    "quak_error_repo_check_failed",
    repo = repo,
    envvar = envvar,
    call = call
  )
}

abort_invalid_azure_url <- function(url, call = rlang::caller_env()) {
  quak_abort(
    "{.arg url} must be an Azure Data Lake Storage URL (abfss://).",
    "quak_error_invalid_azure_url",
    url = url,
    call = call
  )
}

abort_invalid_az_secret <- function(
  message,
  arg = NULL,
  account = NULL,
  call = rlang::caller_env()
) {
  quak_abort(
    message,
    "quak_error_invalid_azure_secret",
    arg = arg,
    account = account,
    call = call
  )
}

abort_ext_unavailable <- function(
  name,
  info,
  url,
  detail,
  parent = NULL,
  call = rlang::caller_env()
) {
  msg <- if (is_connectivity_error_msg(detail)) {
    c(
      "Cannot reach extension repository to install {.pkg {name}}.",
      "!" = "A firewall or proxy may be blocking {.url {url}}.",
      "i" = "Configure a mirror with {.code repo_set_urls()} or {.envvar QUAK_CORE_REPO}.",
      "x" = detail
    )
  } else {
    c(
      "Extension {.pkg {name}} is not available for platform
       {.val {info$platform}} / version {.val {info$version}}.",
      "i" = "Some platforms (e.g. {.val windows_amd64_mingw},
             {.val windows_amd64_rtools}) have limited extension coverage.",
      "i" = "Use {.code repo_check()} to see what is published for your platform.",
      "x" = detail
    )
  }
  quak_abort(
    msg,
    "quak_error_extension_unavailable",
    extension = name,
    platform = info$platform,
    duckdb_version = info$version,
    url = url,
    detail = detail,
    parent = parent,
    call = call
  )
}

abort_ext_install_failed <- function(
  name,
  sql_error,
  manual_error,
  call = rlang::caller_env()
) {
  sql_msg <- conditionMessage(sql_error)
  manual_msg <- conditionMessage(manual_error)

  if (
    is_connectivity_error_msg(sql_msg) || is_connectivity_error_msg(manual_msg)
  ) {
    # Pull out the raw network error detail (first line, or the $detail field for
    # quak_error_extension_unavailable which stores just the curl/HTTP message).
    detail <- if (inherits(manual_error, "quak_error_extension_unavailable")) {
      manual_error$detail
    } else {
      strsplit(manual_msg, "\n")[[1L]][[1L]]
    }
    quak_abort(
      c(
        "Failed to install extension {.pkg {name}}: repository unreachable.",
        "!" = "A corporate firewall or proxy may be blocking the connection.",
        "i" = paste0(
          "Configure a mirror with {.code repo_set_urls()} or ",
          "{.envvar QUAK_CORE_REPO} / {.envvar QUAK_COMMUNITY_REPO}."
        ),
        "x" = detail
      ),
      "quak_error_extension_install_failed",
      extension = name,
      sql_error = sql_error,
      manual_error = manual_error,
      parent = NULL,
      call = call
    )
  } else {
    quak_abort(
      c(
        "Failed to install extension {.pkg {name}}.",
        "x" = "SQL install: {sql_msg}",
        "x" = "Manual install: {manual_msg}"
      ),
      "quak_error_extension_install_failed",
      extension = name,
      sql_error = sql_error,
      manual_error = manual_error,
      parent = manual_error,
      call = call
    )
  }
}

is_connectivity_error_msg <- function(msg) {
  patterns <- c(
    "(HTTP 0)",
    "SSL connect error",
    "TLS connect error",
    "Could not resolve host",
    "Connection refused",
    "Network is unreachable",
    "Failed to connect"
  )
  any(vapply(patterns, grepl, logical(1), x = msg, fixed = TRUE))
}


abort_ext_load_failed <- function(
  name,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    conditionMessage(parent),
    "quak_error_extension_load_failed",
    extension = name,
    parent = parent,
    call = call
  )
}

abort_ext_not_installed <- function(name, call = rlang::caller_env()) {
  quak_abort(
    c(
      "Extension {.pkg {name}} is not installed.",
      "i" = "Set {.code auto_install = TRUE} to install automatically."
    ),
    "quak_error_extension_not_loaded",
    extension = name,
    call = call
  )
}

abort_ext_install_declined <- function(name, call = rlang::caller_env()) {
  quak_abort(
    "Extension {.pkg {name}} is required but installation was declined.",
    "quak_error_extension_not_loaded",
    extension = name,
    call = call
  )
}

warn_ext_reinstall <- function(name, parent, call = rlang::caller_env()) {
  quak_warn(
    c(
      "!" = "Installed extension {.pkg {name}} could not be loaded; reinstalling it.",
      "i" = conditionMessage(parent)
    ),
    "quak_warning_extension_reinstall_corrupt",
    extension = name,
    parent = parent,
    call = call
  )
}

abort_conn_closed <- function(call = rlang::caller_env()) {
  quak_abort(
    "Cannot collect: the DuckDB connection backing this table is closed.",
    "quak_error_connection_closed",
    call = call
  )
}

abort_ext_not_loaded <- function(name, call = rlang::caller_env()) {
  quak_abort(
    c(
      "Cannot collect: the DuckDB {.pkg {name}} extension is not loaded.",
      "i" = "Load it with {.code ext_load('azure', conn = dbplyr::remote_con(x))} before collecting."
    ),
    "quak_error_extension_not_loaded",
    extension = name,
    call = call
  )
}

abort_register_delta <- function(
  name,
  url,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to register Delta table {.val {name}}.",
    "quak_error_register_delta_failed",
    name = name,
    url = url,
    parent = parent,
    call = call
  )
}

abort_register_parquet <- function(
  name,
  url,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to register Parquet dataset {.val {name}}.",
    "quak_error_register_parquet_failed",
    name = name,
    url = url,
    parent = parent,
    call = call
  )
}

abort_register_csv <- function(
  name,
  url,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to register CSV dataset {.val {name}}.",
    "quak_error_register_csv_failed",
    name = name,
    url = url,
    parent = parent,
    call = call
  )
}

abort_register_json <- function(
  name,
  url,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to register JSON dataset {.val {name}}.",
    "quak_error_register_json_failed",
    name = name,
    url = url,
    parent = parent,
    call = call
  )
}

abort_az_copy_failed <- function(
  url,
  format,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to copy data to {.val {url}}.",
    "quak_error_azure_copy_failed",
    url = url,
    format = format,
    parent = parent,
    call = call
  )
}

abort_az_query_failed <- function(
  message,
  url,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    message,
    "quak_error_azure_query_failed",
    url = url,
    parent = parent,
    call = call
  )
}

abort_az_tune_failed <- function(
  setting,
  value,
  parent,
  call = rlang::caller_env()
) {
  quak_abort(
    "Failed to set Azure DuckDB setting {.val {setting}}.",
    "quak_error_azure_tune_failed",
    setting = setting,
    value = value,
    parent = parent,
    call = call
  )
}

warn_az_buffer_not_multiple <- function(
  buffer_size,
  chunk_size,
  call = rlang::caller_env()
) {
  quak_warn(
    c(
      "Azure read buffer size is not evenly divisible by the transfer chunk size.",
      "i" = "{.arg buffer_size} = {.val {buffer_size}}; {.arg chunk_size} = {.val {chunk_size}}."
    ),
    "quak_warning_azure_tune_buffer_size",
    buffer_size = buffer_size,
    chunk_size = chunk_size,
    call = call
  )
}

abort_file_copy_failed <- function(parent, call = rlang::caller_env()) {
  quak_abort(
    conditionMessage(parent),
    "quak_error_file_copy_failed",
    parent = parent,
    call = call
  )
}

warn_unknown_setting <- function(name, call = rlang::caller_env()) {
  quak_warn(
    "Unknown DuckDB setting {.val {name}}.",
    "quak_warning_unknown_setting",
    setting = name,
    call = call
  )
}
