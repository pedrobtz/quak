#' Default DuckDB extension cache directory
#'
#' Resolution order: in-memory value (`opts$set("cache_dir", ...)`) ->
#' env var `QUAK_CACHE_DIR` -> OS-appropriate user cache directory via
#' [tools::R_user_dir()].
#'
#' @return Character scalar. The resolved cache path.
#' @examples
#' ext_cache_path()
#' @export
ext_cache_path <- function() {
  opts$get("cache_dir")
}

#' Extension cache
#'
#' Builds an `ext_cache` object: a list of closures bound to a cache directory,
#' implementing CRUD over cached `.duckdb_extension` files. Files are laid out
#' under `<cache_path>/<version>/<platform>/<name>.duckdb_extension`.
#'
#' @param cache_path Character scalar. Cache root directory. Defaults to
#'   [ext_cache_path()].
#' @return An `ext_cache` object (a list of closures) with elements:
#'   * `.path`: the cache root.
#'   * `get(name, version, platform)`: path to the cached extension, or `NULL`.
#'   * `add(name, version, platform, src)`: copies `src` into the cache.
#'   * `list()`: data frame of cached extensions.
#'   * `del(name, version, platform)`: removes a cached extension. When `version`
#'    and `platform` are omitted, removes all cached entries for `name`.
#' @examples
#' cache <- ext_cache(file.path(tempdir(), "quak-cache"))
#' cache$.path
#' @export
ext_cache <- function(cache_path = ext_cache_path()) {
  if (!rlang::is_string(cache_path)) {
    abort_bad_arg(
      "{.arg cache_path} must be a character scalar.",
      arg = "cache_path",
      value = cache_path
    )
  }

  ext_file <- function(name, version, platform) {
    ext_cache_check_key(name, version, platform)
    fs::path(cache_path, version, platform, paste0(name, ".duckdb_extension"))
  }

  empty_listing <- function() {
    try_as_tibble(data.frame(
      name = character(),
      version = character(),
      platform = character(),
      size = fs::fs_bytes(),
      modified = .POSIXct(numeric())
    ))
  }

  get <- function(name, version, platform) {
    f <- ext_file(name, version, platform)
    if (!fs::file_exists(f)) {
      return(NULL)
    }
    fs::path(f)
  }

  add <- function(name, version, platform, src) {
    if (!rlang::is_string(src)) {
      abort_bad_arg(
        "{.arg src} must be a character scalar.",
        arg = "src",
        value = src
      )
    }
    if (!fs::file_exists(src)) {
      abort_bad_arg(
        "{.arg src} {.path {src}} does not exist.",
        arg = "src",
        value = src
      )
    }
    dest <- ext_file(name, version, platform)
    fs::dir_create(fs::path_dir(dest))
    file_copy_atomic(src, dest)
    invisible(dest)
  }

  list_files <- function() {
    if (!fs::dir_exists(cache_path)) {
      return(empty_listing())
    }
    files <- fs::dir_ls(
      cache_path,
      type = "file",
      recurse = TRUE,
      glob = "*.duckdb_extension"
    )
    if (length(files) == 0L) {
      return(empty_listing())
    }

    info <- fs::file_info(files)
    rel <- fs::path_rel(info$path, cache_path)
    parts <- strsplit(rel, "/", fixed = TRUE)

    pick <- function(i) {
      vapply(
        parts,
        function(x) if (length(x) >= 3L) x[[i]] else NA_character_,
        character(1)
      )
    }

    try_as_tibble(data.frame(
      name = sub(
        "\\.duckdb_extension$",
        "",
        as.character(fs::path_file(info$path))
      ),
      version = pick(1L),
      platform = pick(2L),
      size = info$size,
      modified = info$modification_time
    ))
  }

  del <- function(name, version = NULL, platform = NULL) {
    if (!rlang::is_string(name)) {
      abort_bad_arg(
        "{.arg name} must be a character scalar.",
        arg = "name",
        value = name
      )
    }
    if (is.null(version) && is.null(platform)) {
      listing <- list_files()
      matches <- listing[listing$name == name, ]
      if (nrow(matches) == 0L) {
        cli::cli_inform(c("i" = "No cached entries for {.pkg {name}}."))
        return(invisible(FALSE))
      }
      files <- fs::path(
        cache_path,
        matches$version,
        matches$platform,
        paste0(matches$name, ".duckdb_extension")
      )
      fs::file_delete(files)
      cli::cli_inform(c(
        "v" = "Deleted {nrow(matches)} cached entr{?y/ies} for {.pkg {name}}."
      ))
      return(invisible(TRUE))
    }
    f <- ext_file(name, version, platform)
    if (!fs::file_exists(f)) {
      cli::cli_inform(c("i" = "No cached extension at {.path {f}}."))
      return(invisible(FALSE))
    }
    fs::file_delete(f)
    cli::cli_inform(c("v" = "Deleted {.path {f}}."))
    invisible(TRUE)
  }

  structure(
    list(
      .path = cache_path,
      get = get,
      add = add,
      list = list_files,
      del = del
    ),
    class = "ext_cache"
  )
}

file_copy_atomic <- function(src, dest) {
  dest_dir <- fs::path_dir(dest)
  fs::dir_create(dest_dir)

  tmp <- tempfile(
    pattern = paste0(as.character(fs::path_file(dest)), "-"),
    tmpdir = dest_dir
  )
  backup <- tempfile(
    pattern = paste0(as.character(fs::path_file(dest)), "-backup-"),
    tmpdir = dest_dir
  )
  had_dest <- fs::file_exists(dest)
  backed_up <- FALSE

  tryCatch(
    {
      if (had_dest) {
        fs::file_move(dest, backup)
        backed_up <- TRUE
      }
      fs::file_copy(src, tmp, overwrite = TRUE)
      fs::file_move(tmp, dest)
      if (had_dest && fs::file_exists(backup)) {
        fs::file_delete(backup)
      }
      invisible(dest)
    },
    error = function(e) {
      if (fs::file_exists(tmp)) {
        fs::file_delete(tmp)
      }
      if ((!had_dest || backed_up) && fs::file_exists(dest)) {
        fs::file_delete(dest)
      }
      if (backed_up && fs::file_exists(backup)) {
        fs::file_move(backup, dest)
      }
      abort_file_copy_failed(e)
    }
  )
}

ext_cache_check_key <- function(
  name,
  version,
  platform,
  call = rlang::caller_env()
) {
  if (!rlang::is_string(name)) {
    abort_bad_arg(
      "{.arg name} must be a character scalar.",
      arg = "name",
      value = name,
      call = call
    )
  }
  if (!rlang::is_string(version)) {
    abort_bad_arg(
      "{.arg version} must be a character scalar.",
      arg = "version",
      value = version,
      call = call
    )
  }
  if (!rlang::is_string(platform)) {
    abort_bad_arg(
      "{.arg platform} must be a character scalar.",
      arg = "platform",
      value = platform,
      call = call
    )
  }
  invisible(NULL)
}

#' @export
print.ext_cache <- function(x, ...) {
  n <- nrow(x$list())
  cli::cli_h1("ext_cache")
  cli::cli_text("{n} file{?s} cached")
  cli::cli_text("path: {.path {x$.path}}")
  invisible(x)
}
