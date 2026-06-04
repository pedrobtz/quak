#' Get DuckDB extension repository URLs
#'
#' Returns the currently active repository URLs. Resolution order per repo:
#' R option (`quak.core_repo` / `quak.community_repo`) -> env var
#' (`QUAK_CORE_REPO` / `QUAK_COMMUNITY_REPO`) -> built-in default.
#'
#' @return A named list with elements `core` and `community`.
#' @examples
#' repo_urls()
#' @export
repo_urls <- function() {
  list(
    core = opts$get("core_repo"),
    community = opts$get("community_repo")
  )
}


#' Set DuckDB extension repository URLs
#'
#' Stores URLs in R options `quak.core_repo` / `quak.community_repo` so they
#' can be configured org-wide in `.Rprofile`. When `core` is supplied, also
#' sets DuckDB's `custom_extension_repository` on `conn`; passing `NULL`
#' resets that connection setting to DuckDB's default.
#'
#' @param core Optional character scalar. URL for the core extension repository.
#'   Omit to leave the current value unchanged. Pass `NULL` to reset to the
#'   DuckDB default.
#' @param community Optional character scalar. URL for the community extension
#'   repository. Omit to leave the current value unchanged. Pass `NULL` to
#'   reset to the DuckDB default.
#' @param check Logical. If `TRUE` (default), calls [repo_check()] for each
#'   repository whose URL was changed, probing `"httpfs"` as a baseline
#'   extension.
#' @param conn A DuckDB connection. Defaults to [conn_default()]. Used to set
#'   `custom_extension_repository` when `core` is supplied, and by
#'   [repo_check()] when `check = TRUE`.
#' @return Invisibly returns a named list with elements `core` and `community`
#'   reflecting the current option values.
#' @examples
#' old <- repo_urls()
#' repo_set_urls(core = "https://extensions.example.com", check = FALSE)
#' repo_urls()
#' repo_set_urls(core = old$core, check = FALSE)
#' @export
repo_set_urls <- function(
  core = NULL,
  community = NULL,
  check = TRUE,
  conn = conn_default()
) {
  if (!missing(core)) {
    if (!is.null(core) && !rlang::is_string(core)) {
      abort_bad_arg(
        "{.arg core} must be a character scalar or {.code NULL}.",
        arg = "core",
        value = core
      )
    }
    opts$set("core_repo", core)
    repo_set_core_conn_url(core, conn)
    if (check) {
      ok <- repo_check("core", conn = conn)
      if (!all(ok)) {
        abort_repo_check_failed("core", names(ok)[!ok])
      }
    }
  }
  if (!missing(community)) {
    if (!is.null(community) && !rlang::is_string(community)) {
      abort_bad_arg(
        "{.arg community} must be a character scalar or {.code NULL}.",
        arg = "community",
        value = community
      )
    }
    opts$set("community_repo", community)
    if (check) {
      ok <- repo_check("community", conn = conn)
      if (!all(ok)) {
        abort_repo_check_failed("community", names(ok)[!ok])
      }
    }
  }
  invisible(repo_urls())
}

repo_set_core_conn_url <- function(core, conn = conn_default()) {
  core <- if (is.null(core)) "" else core
  conn_setting(conn, "custom_extension_repository", core)
  invisible(conn)
}

#' Assemble an extension download URL
#'
#' Pure URL builder — no I/O, no connection required. Concatenates the
#' repository base URL, DuckDB version, platform, and extension filename with
#' `/` (correct for URLs on all platforms).
#'
#' @param repo_url Character scalar. Repository base URL.
#' @param version Character scalar. DuckDB version string (e.g. `"v1.2.0"`).
#' @param platform Character scalar. Platform string (e.g. `"osx_arm64"`).
#' @param name Character scalar. Extension name (e.g. `"httpfs"`).
#' @return Character scalar. Full URL to the `.duckdb_extension.gz` file.
#' @keywords internal
repo_ext_url <- function(repo_url, version, platform, name) {
  paste(
    repo_url,
    version,
    platform,
    paste0(name, ".duckdb_extension.gz"),
    sep = "/"
  )
}

#' Check which extension names are available in a repository
#'
#' Sends a HEAD request for each name in `ext` against the given repository
#' and reports which ones the server serves (2xx). Use this to discover which
#' extensions are actually published for the running DuckDB version and
#' platform.
#'
#' @param repo `"core"` or `"community"`.
#' @param ext Character vector of extension names to probe. Required.
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return Invisibly returns a named logical vector, one element per name in
#'   `ext`.
#' @keywords internal
repo_check <- function(
  repo = c("core", "community"),
  ext = NULL,
  conn = conn_default(),
  verbose = FALSE
) {
  repo <- rlang::arg_match(repo)
  if (is.null(ext)) {
    ext <- c(core = "httpfs", community = "h3")[[repo]]
  }
  if (!is.character(ext) || length(ext) == 0L) {
    abort_bad_arg(
      "{.arg ext} must be a non-empty character vector.",
      arg = "ext",
      value = ext
    )
  }

  urls <- rlang::set_names(
    lapply(ext, function(e) ext_url(e, repo = repo, conn = conn)),
    ext
  )
  ok <- vapply(
    urls,
    repo_head_ok,
    logical(1)
  )

  if (verbose) {
    for (nm in names(ok)) {
      if (ok[[nm]]) {
        cli::cli_inform(c("v" = "{.pkg {nm}}: {.emph OK}"))
      } else {
        cli::cli_inform(c("x" = "{.pkg {nm}}: {.emph not found}"))
      }
    }
  }
  invisible(ok)
}

repo_startup_check <- function() {
  if (!opts$get("startup_repo_check")) {
    return(invisible(NULL))
  }
  for (nm in c("core", "community")) {
    ok <- repo_check(nm)
    if (!all(ok)) {
      url <- opts$get(paste0(nm, "_repo"))
      cli::cli_alert_warning(
        "quak: {nm} repository may be unreachable: {.url {url}}"
      )
    }
  }
  invisible(NULL)
}

repo_head_ok <- function(url) {
  resp <- repo_head_probe(url)
  !inherits(resp, "error") && http_status_ok(resp$status_code)
}

repo_head_probe <- function(url) {
  handle <- curl::new_handle(nobody = TRUE, followlocation = TRUE)
  tryCatch(
    curl::curl_fetch_memory(url, handle = handle),
    error = function(e) e
  )
}

http_status_ok <- function(status_code) {
  status_code >= 200L && status_code < 300L
}
