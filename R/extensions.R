#' Find the DuckDB extension folder
#'
#' Returns the path where DuckDB stores installed extension files.
#' This is determined by the `extension_directory` setting.
#'
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return Character scalar. Path to the extension directory.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_dir(conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
ext_dir <- function(conn = conn_default()) {
  result <- DBI::dbGetQuery(
    conn,
    "SELECT current_setting('extension_directory') AS ext_dir"
  )
  result$ext_dir[[1L]]
}

#' Set the DuckDB extension folder
#'
#' Changes the path where DuckDB stores installed extension files for `conn`.
#' The value is written to DuckDB's `extension_directory` setting.
#'
#' @param path Character scalar. Path to the extension directory.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @param create Logical. If `TRUE`, create `path` before setting it.
#' @return Invisibly returns the normalized extension directory path.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_set_dir(file.path(tempdir(), "quak-exts"), conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
ext_set_dir <- function(path, conn = conn_default(), create = TRUE) {
  check_required_arg(path, "path")
  if (!rlang::is_string(path) || !nzchar(path)) {
    abort_bad_arg(
      "{.arg path} must be a non-empty character scalar.",
      arg = "path",
      value = path
    )
  }
  if (!rlang::is_bool(create)) {
    abort_bad_arg(
      "{.arg create} must be `TRUE` or `FALSE`.",
      arg = "create",
      value = create
    )
  }

  path <- fs::path_abs(path)
  if (create) {
    fs::dir_create(path, recurse = TRUE)
  } else if (!fs::dir_exists(path)) {
    abort_bad_arg("{.path {path}} does not exist.", arg = "path", value = path)
  }

  stmt <- glue::glue_sql("SET extension_directory = {path}", .con = conn)
  DBI::dbExecute(conn, stmt)
  invisible(as.character(path))
}

#' Check whether a DuckDB extension is installed
#'
#' @param name Character scalar. Extension name.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return Logical scalar.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_is_installed("httpfs", conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
ext_is_installed <- function(name, conn = conn_default()) {
  check_required_arg(name, "name")
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  name %in% ext_list_installed(conn)$name
}

#' Build an extension download URL
#'
#' Combines a repository base URL with the running DuckDB version and platform
#' to produce the full path to an extension archive. When `repo_url` is
#' supplied it overrides the configured `repo` URL.
#'
#' @param ext Character scalar. Extension name.
#' @param repo `"core"` or `"community"`. Selects which configured repository
#'   URL to use. Ignored when `repo_url` is non-`NULL`.
#' @param repo_url Optional character scalar. Explicit base URL overriding
#'   `repo`'s configured URL.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return A character scalar URL.
#' @keywords internal
ext_url <- function(
  ext,
  repo = c("core", "community"),
  repo_url = NULL,
  conn = conn_default()
) {
  if (!rlang::is_string(ext)) {
    abort_bad_arg(
      "{.arg ext} must be a character scalar.",
      arg = "ext",
      value = ext
    )
  }
  if (!is.null(repo_url) && !rlang::is_string(repo_url)) {
    abort_bad_arg(
      "{.arg repo_url} must be a character scalar or {.code NULL}.",
      arg = "repo_url",
      value = repo_url
    )
  }
  if (is.null(repo_url)) {
    key <- rlang::arg_match(repo)
    repo_url <- repo_urls()[[key]]
    if (is.null(repo_url)) {
      evar <- paste0("QUAK_", toupper(key), "_REPO")
      abort_repo_url_missing(key, evar)
    }
  }
  info <- conn_info(conn)
  repo_ext_url(repo_url, info$version, info$platform, ext)
}

#' Install a DuckDB extension
#'
#' Tries two strategies in order, succeeding as soon as one works:
#'
#' 1. **SQL install:** runs DuckDB's built-in `INSTALL` (using the configured
#'    repository URL when one is set via [repo_set_urls()], the
#'    `QUAK_CORE_REPO` / `QUAK_COMMUNITY_REPO` env vars, or the
#'    `quak.core_repo` / `quak.community_repo` R options).
#' 2. **Manual fallback:** when the SQL install fails (e.g. DuckDB cannot
#'    reach an HTTPS URL before `httpfs` is loaded, whereas R's `curl` can),
#'    downloads the `.duckdb_extension` file, caches it, and copies it into
#'    the extension directory.
#'
#' A SQL failure is never raised on its own — it only surfaces (as a warning,
#' when `verbose = TRUE`) if the manual fallback also runs. An error is raised
#' only when both strategies fail.
#'
#' Idempotent — skips install if the extension is already installed
#' (checked via the `duckdb_extensions()` pragma).
#'
#' @param name Character scalar. Extension name.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @param cache An `ext_cache` object used by the manual fallback.
#' @param repo `"core"` or `"community"`. Determines which configured URL to
#'   use and, when no URL is set, which DuckDB install syntax to emit.
#' @param verbose Logical or `NULL`. When `TRUE`, emits a warning if the SQL
#'   install fails but the manual fallback succeeds. When `NULL` (default),
#'   uses the `quak.install_verbose` option / `QUAK_INSTALL_VERBOSE` env var.
#'   When `FALSE`, the fallback is silent. Either way, a SQL failure is never
#'   raised as an error on its own.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires network access to download the extension.
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_install("httpfs", conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' }
#' @export
ext_install <- function(
  name,
  cache = ext_cache(),
  repo = c("core", "community"),
  conn = conn_default(),
  verbose = NULL
) {
  check_required_arg(name, "name")
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!inherits(cache, "ext_cache")) {
    abort_bad_arg(
      "{.arg cache} must be an {.cls ext_cache} object.",
      arg = "cache",
      value = cache
    )
  }
  if (is.null(verbose)) {
    verbose <- opts$get("install_verbose")
  }
  if (!rlang::is_bool(verbose)) {
    abort_bad_arg(
      "{.arg verbose} must be `TRUE`, `FALSE`, or `NULL`.",
      arg = "verbose",
      value = verbose
    )
  }
  repo <- rlang::arg_match(repo)

  if (ext_is_installed(name, conn)) {
    cli::cli_inform(c("i" = "Extension {.pkg {name}} is already installed."))
    return(invisible(conn))
  }

  repo_url <- opts$get(paste0(repo, "_repo"), default = NULL)
  installed_file <- ext_snapshot_installed_file(name, conn)
  on.exit(ext_cleanup_snapshot(installed_file), add = TRUE)

  # Always try DuckDB's SQL INSTALL first, then fall back to a manual download.
  # SQL may fail (e.g. DuckDB can't reach HTTPS before httpfs is loaded) where
  # R's curl succeeds, so a SQL failure is not fatal on its own.
  sql_err <- tryCatch(
    {
      ext_install_sql(name, repo = repo, repo_url = repo_url, conn = conn)
      NULL
    },
    error = function(e) e
  )

  if (is.null(sql_err)) {
    ext_commit_snapshot(installed_file)
    return(invisible(conn))
  }
  ext_restore_installed_file(installed_file)

  if (verbose) {
    cli::cli_inform(c(
      "!" = "SQL {.code INSTALL} failed for {.pkg {name}}; trying manual install."
    ))
  }

  manual_err <- tryCatch(
    {
      ext_install_manual(name, cache = cache, repo = repo, conn = conn)
      NULL
    },
    error = function(e) e
  )

  if (is.null(manual_err)) {
    ext_commit_snapshot(installed_file)
    return(invisible(conn))
  }
  ext_restore_installed_file(installed_file)
  ext_commit_snapshot(installed_file)

  # Both paths failed — surface a single error carrying both causes.
  abort_ext_install_failed(name, sql_err, manual_err)
}

#' Install an extension via DuckDB's SQL INSTALL command
#'
#' @param conn A DuckDB connection.
#' @param name Character scalar. Extension name.
#' @param repo `"core"` or `"community"`. Only relevant when `repo_url` is
#'   `NULL`: community extensions emit `INSTALL name FROM community`.
#' @param repo_url Character scalar or `NULL`. When non-`NULL`, emits
#'   `INSTALL name FROM 'url'`. When `NULL`, falls back to the repo-specific
#'   default: plain `INSTALL name` for core, `INSTALL name FROM community`
#'   for community.
#' @return Invisibly returns `conn`.
#' @keywords internal
ext_install_sql <- function(
  name,
  repo = c("core", "community"),
  repo_url = NULL,
  conn = conn_default()
) {
  repo <- match.arg(repo)
  if (!is.null(repo_url)) {
    stmt <- glue::glue_sql("INSTALL {`name`} FROM {repo_url}", .con = conn)
    done <- "Installed {.pkg {name}} from {.url {repo_url}}."
  } else if (repo == "community") {
    stmt <- glue::glue_sql("INSTALL {`name`} FROM community", .con = conn)
    done <- "Installed community extension {.pkg {name}}."
  } else {
    stmt <- glue::glue_sql("INSTALL {`name`}", .con = conn)
    done <- "Installed {.pkg {name}}."
  }
  DBI::dbExecute(conn, stmt)
  cli::cli_inform(c("v" = done))
  invisible(conn)
}

#' Install an extension manually using the cache
#'
#' Looks the extension up in `cache`. On a hit the cached
#' `.duckdb_extension` file is copied into the connection's
#' `extension_directory`. On a miss `ext_download()` is invoked first to
#' populate the cache, and the freshly-cached file is copied.
#'
#' @param conn A DuckDB connection.
#' @param name Character scalar. Extension name.
#' @param cache An `ext_cache` object.
#' @param repo `"core"` or `"community"`. Forwarded to `ext_download()` on
#'   cache miss.
#' @return Invisibly returns `conn`.
#' @keywords internal
ext_install_manual <- function(
  name,
  cache = ext_cache(),
  repo = "core",
  conn = conn_default()
) {
  info <- conn_info(conn)
  src <- cache$get(name, info$version, info$platform)
  downloaded <- FALSE
  installed <- FALSE
  on.exit(
    {
      if (downloaded && !installed) {
        cache$del(name, info$version, info$platform)
      }
    },
    add = TRUE
  )

  if (is.null(src)) {
    src <- ext_download(name, repo = repo, cache = cache, conn = conn)
    downloaded <- TRUE
  } else {
    cli::cli_inform(c("i" = "Using cached {.pkg {name}} at {.path {src}}."))
  }

  dir <- fs::path(ext_dir(conn), info$version, info$platform)
  fs::dir_create(dir, recurse = TRUE)
  dest <- fs::path(dir, paste0(name, ".duckdb_extension"))

  file_copy_atomic(src, dest)
  cli::cli_inform(c("v" = "Installed {.pkg {name}} from {.path {src}}."))
  installed <- TRUE

  invisible(conn)
}

ext_installed_file <- function(name, conn, info = conn_info(conn)) {
  fs::path(
    ext_dir(conn),
    info$version,
    info$platform,
    paste0(name, ".duckdb_extension")
  )
}

ext_snapshot_installed_file <- function(name, conn) {
  path <- ext_installed_file(name, conn)
  snapshot <- new.env(parent = emptyenv())
  snapshot$path <- path
  snapshot$backup <- NULL
  snapshot$had_file <- fs::file_exists(path)
  snapshot$done <- FALSE

  if (snapshot$had_file) {
    snapshot$backup <- tempfile(
      pattern = paste0(as.character(fs::path_file(path)), "-rollback-"),
      tmpdir = fs::path_dir(path)
    )
    fs::file_copy(path, snapshot$backup, overwrite = TRUE)
  }

  snapshot
}

ext_restore_installed_file <- function(snapshot) {
  if (fs::file_exists(snapshot$path)) {
    fs::file_delete(snapshot$path)
  }
  if (snapshot$had_file && fs::file_exists(snapshot$backup)) {
    fs::dir_create(fs::path_dir(snapshot$path))
    fs::file_copy(snapshot$backup, snapshot$path, overwrite = TRUE)
  }
  invisible(snapshot$path)
}

ext_commit_snapshot <- function(snapshot) {
  if (!is.null(snapshot$backup) && fs::file_exists(snapshot$backup)) {
    fs::file_delete(snapshot$backup)
  }
  snapshot$done <- TRUE
  invisible(snapshot$path)
}

ext_cleanup_snapshot <- function(snapshot) {
  if (!isTRUE(snapshot$done)) {
    restored <- tryCatch(
      {
        ext_restore_installed_file(snapshot)
        TRUE
      },
      error = function(e) FALSE
    )
    if (restored) {
      ext_commit_snapshot(snapshot)
    }
  }
  invisible(snapshot$path)
}

#' Install a DuckDB extension from a local file
#'
#' Executes `INSTALL '/path/to/ext.duckdb_extension'` on `conn`. Use this to
#' install an extension binary you already have on disk without going through a
#' remote repository.
#'
#' @param path Character scalar. Path to the `.duckdb_extension` file.
#' @param name Character scalar. Extension name used in messages. Inferred
#'   from `path` when omitted.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a local DuckDB extension file at the given path.
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_install_local("/path/to/httpfs.duckdb_extension", conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' }
#' @export
ext_install_local <- function(path, name = NULL, conn = conn_default()) {
  check_required_arg(path, "path")
  if (!rlang::is_string(path) || !nzchar(path)) {
    abort_bad_arg(
      "{.arg path} must be a non-empty character scalar.",
      arg = "path",
      value = path
    )
  }
  if (!fs::file_exists(path)) {
    abort_bad_arg(
      "{.arg path} {.path {path}} does not exist.",
      arg = "path",
      value = path
    )
  }
  path <- as.character(fs::path_abs(path))
  if (is.null(name)) {
    name <- sub("\\.duckdb_extension$", "", fs::path_file(path))
  }
  DBI::dbExecute(conn, glue::glue_sql("INSTALL {path}", .con = conn))
  cli::cli_inform(c("v" = "Installed {.pkg {name}} from {.path {path}}."))
  invisible(conn)
}

#' List installed DuckDB extensions
#'
#' Queries `duckdb_extensions()`, returning only extensions where `installed = TRUE`.
#'
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return A [tibble::tibble()] with columns: `name`, `installed`, `loaded`, `version`, `description`.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_list_installed(conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
ext_list_installed <- function(conn = conn_default()) {
  try_as_tibble(DBI::dbGetQuery(
    conn,
    "SELECT
      extension_name AS name,
      installed,
      loaded,
      extension_version AS version,
      description
    FROM duckdb_extensions()
    WHERE installed"
  ))
}

#' List all DuckDB core extensions
#'
#' Returns the full catalog of extensions maintained by the DuckDB core team,
#' regardless of whether they are installed.
#'
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return A [tibble::tibble()] with columns: `name`, `version`, `description`.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_list_available(conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
ext_list_available <- function(conn = conn_default()) {
  try_as_tibble(DBI::dbGetQuery(
    conn,
    "SELECT
      extension_name AS name,
      extension_version AS version,
      description
    FROM duckdb_extensions()
    WHERE installed_from IS NULL OR installed_from != 'community'"
  ))
}


#' Uninstall a DuckDB extension
#'
#' Removes the extension file from DuckDB's `extension_directory`. Optionally
#' also purges the corresponding entry from the local cache.
#'
#' @param name Character scalar. Extension name.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @param purge_cache Logical. If `TRUE`, also removes the file from `cache`.
#' @param cache An `ext_cache` object. Only used when `purge_cache = TRUE`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a connection with the extension already installed.
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_uninstall("httpfs", conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' }
#' @export
ext_uninstall <- function(
  name,
  purge_cache = FALSE,
  cache = ext_cache(),
  conn = conn_default()
) {
  check_required_arg(name, "name")
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(purge_cache)) {
    abort_bad_arg(
      "{.arg purge_cache} must be `TRUE` or `FALSE`.",
      arg = "purge_cache",
      value = purge_cache
    )
  }

  info <- conn_info(conn)
  ext_file <- ext_installed_file(name, conn, info)

  if (!fs::file_exists(ext_file)) {
    cli::cli_inform(c("i" = "Extension {.pkg {name}} is not installed."))
    return(invisible(conn))
  }

  fs::file_delete(ext_file)
  cli::cli_inform(c("v" = "Uninstalled {.pkg {name}} ({.path {ext_file}})."))

  if (purge_cache) {
    cache$del(name, info$version, info$platform)
  }

  invisible(conn)
}

ext_download <- function(
  name,
  repo = c("core", "community"),
  cache = ext_cache(),
  conn = conn_default()
) {
  info <- conn_info(conn)
  url <- ext_url(name, repo = repo, conn = conn)

  # Pre-flight HEAD probe: detect connectivity failures before the full download.
  probe <- repo_head_probe(url)
  if (inherits(probe, "error") || !http_status_ok(probe$status_code)) {
    detail <- if (inherits(probe, "error")) {
      conditionMessage(probe)
    } else {
      paste0("HTTP ", probe$status_code)
    }
    abort_ext_unavailable(
      name,
      info = info,
      url = url,
      detail = detail,
      parent = if (inherits(probe, "error")) probe else NULL,
      call = rlang::caller_env()
    )
  }

  cli::cli_inform(c("i" = "Downloading {.pkg {name}} from {.url {url}}."))

  gz_path <- tempfile(fileext = ".duckdb_extension.gz")
  on.exit(unlink(gz_path, force = TRUE), add = TRUE)

  resp <- tryCatch(
    ext_download_file(url, gz_path),
    error = function(e) e
  )
  if (inherits(resp, "error") || !http_status_ok(resp$status_code)) {
    detail <- if (inherits(resp, "error")) {
      conditionMessage(resp)
    } else {
      paste0("HTTP status ", resp$status_code)
    }
    abort_ext_unavailable(
      name,
      info = info,
      url = url,
      detail = detail,
      parent = if (inherits(resp, "error")) resp else NULL,
      call = rlang::caller_env()
    )
  }

  ext_path <- tempfile(fileext = ".duckdb_extension")
  on.exit(unlink(ext_path, force = TRUE), add = TRUE)

  gunzip_file(gz_path, ext_path)

  cached <- cache$add(name, info$version, info$platform, ext_path)
  cli::cli_inform(c("v" = "Cached {.pkg {name}} at {.path {cached}}."))
  cached
}

ext_download_file <- function(url, path) {
  handle <- curl::new_handle(followlocation = TRUE)
  curl::curl_fetch_disk(url, path, handle = handle)
}

#' Decompress a gzip file to a destination path
#'
#' Streams `src` (a gzip-compressed file) through [gzfile()] into `dest`,
#' fully closing both connections before returning. Closing the output
#' connection flushes R's internal buffer to disk; skipping that step can
#' leave the trailing bytes — where a `.duckdb_extension` stores its metadata
#' footer — unwritten, yielding a corrupt file.
#'
#' @param src Character scalar. Path to the gzip-compressed source file.
#' @param dest Character scalar. Path to write the decompressed output to.
#' @return Invisibly returns `dest`.
#' @keywords internal
gunzip_file <- function(src, dest) {
  gz_con <- gzfile(src, "rb")
  out_con <- file(dest, "wb")
  # Close output first so its buffer is flushed before any caller reads `dest`.
  on.exit(close(gz_con), add = TRUE)
  on.exit(close(out_con), add = TRUE, after = FALSE)

  chunk_size <- 8L * 1024L * 1024L
  repeat {
    chunk <- readBin(gz_con, "raw", n = chunk_size)
    if (length(chunk) == 0L) {
      break
    }
    writeBin(chunk, out_con)
  }

  invisible(dest)
}


#' Load a DuckDB extension, installing it first if necessary
#'
#' When `path` is supplied, executes `LOAD '/path/to/ext.duckdb_extension'`
#' directly — no install check or auto-install occurs. When only `name` is
#' supplied, returns immediately if the extension is already loaded. Otherwise
#' it checks whether the extension is installed; if not and
#' `auto_install = TRUE`, installs it (prompting first when `ask = TRUE` and
#' the session is interactive), then executes `LOAD <name>`.
#'
#' @param name Character scalar. Extension name. When `path` is supplied,
#'   `name` is inferred from the filename and used only in messages.
#' @param path Optional character scalar. Path to a local
#'   `.duckdb_extension` file. When supplied, the extension is loaded directly
#'   from disk, bypassing the install check and [ext_install()].
#' @param auto_install Logical. Install automatically when the extension is
#'   missing. Default `TRUE`. Ignored when `path` is supplied.
#' @param ask Logical. Prompt the user before installing. Defaults to
#'   [rlang::is_interactive()], so it never prompts during tests or in
#'   non-interactive sessions. Ignored when `auto_install = FALSE` or `path`
#'   is supplied.
#' @param cache An `ext_cache` object forwarded to [ext_install()] on
#'   auto-install. Ignored when `path` is supplied.
#' @param repo `"core"` or `"community"`. Forwarded to [ext_install()].
#'   Ignored when `path` is supplied.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires network access to download and load the extension.
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' ext_load("httpfs", conn = conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' }
#' @export
ext_load <- function(
  name = NULL,
  path = NULL,
  conn = conn_default(),
  auto_install = TRUE,
  ask = rlang::is_interactive(),
  cache = ext_cache(),
  repo = c("core", "community")
) {
  if (!is.null(path)) {
    if (!rlang::is_string(path) || !nzchar(path)) {
      abort_bad_arg(
        "{.arg path} must be a non-empty character scalar.",
        arg = "path",
        value = path
      )
    }
    if (!fs::file_exists(path)) {
      abort_bad_arg(
        "{.arg path} {.path {path}} does not exist.",
        arg = "path",
        value = path
      )
    }
    path <- as.character(fs::path_abs(path))
    if (is.null(name)) {
      name <- sub("\\.duckdb_extension$", "", fs::path_file(path))
    }
    DBI::dbExecute(conn, glue::glue_sql("LOAD {path}", .con = conn))
    cli::cli_inform(c(
      "v" = "Loaded extension {.pkg {name}} from {.path {path}}."
    ))
    return(invisible(conn))
  }

  if (is.null(name)) {
    abort_bad_arg("Either {.arg name} or {.arg path} must be supplied.")
  }
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }
  if (!rlang::is_bool(auto_install)) {
    abort_bad_arg(
      "{.arg auto_install} must be `TRUE` or `FALSE`.",
      arg = "auto_install",
      value = auto_install
    )
  }
  repo <- rlang::arg_match(repo)

  if (ext_is_loaded(name, conn)) {
    return(invisible(conn))
  }

  if (!ext_is_installed(name, conn)) {
    if (!auto_install) {
      abort_ext_not_installed(name)
    }

    if (ask) {
      answer <- utils::askYesNo(
        paste0("Extension '", name, "' is not installed. Install now?"),
        default = TRUE
      )
      if (!isTRUE(answer)) {
        abort_ext_install_declined(name)
      }
    }

    ext_install(name, conn = conn, cache = cache, repo = repo)
  }

  err <- tryCatch(
    {
      ext_load_sql(name, conn)
      NULL
    },
    error = function(e) e
  )
  if (is.null(err)) {
    return(invisible(conn))
  }

  if (!auto_install || !ext_load_reinstallable_error(err)) {
    abort_ext_load_failed(name, err)
  }

  warn_ext_reinstall(name, err)
  ext_uninstall(name, purge_cache = TRUE, cache = cache, conn = conn)
  ext_install(name, conn = conn, cache = cache, repo = repo, verbose = FALSE)
  ext_load_sql(name, conn)
  invisible(conn)
}

ext_load_sql <- function(name, conn) {
  DBI::dbExecute(conn, glue::glue_sql("LOAD {`name`}", .con = conn))
  cli::cli_inform(c("v" = "Loaded extension {.pkg {name}}."))
  invisible(conn)
}

ext_is_loaded <- function(name, conn = conn_default()) {
  check_required_arg(name, "name")
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name
    )
  }

  result <- DBI::dbGetQuery(
    conn,
    glue::glue_sql(
      "SELECT loaded FROM duckdb_extensions() WHERE extension_name = {name}",
      .con = conn
    )
  )
  nrow(result) > 0L && isTRUE(result$loaded[[1L]])
}

ext_load_reinstallable_error <- function(err) {
  msg <- conditionMessage(err)
  patterns <- c(
    "not a DuckDB extension",
    "metadata at the end of the file is invalid"
  )
  any(vapply(
    patterns,
    function(pattern) grepl(pattern, msg, fixed = TRUE),
    logical(1)
  ))
}
