# Package option registry.
# Each entry: value (set via opts$set), env (env var name), default (built-in fallback).
# opts$get() resolution order: value -> options(quak.*) -> Sys.getenv(env) -> default
opts <- local({
  .spec <- list2env(
    list(
      cache_dir = list(
        value = NULL,
        env = "QUAK_CACHE_DIR",
        default = tools::R_user_dir("quak", "cache")
      ),
      core_repo = list(
        value = NULL,
        env = "QUAK_CORE_REPO",
        default = "https://extensions.duckdb.org"
      ),
      default_scope = list(
        value = NULL,
        env = "QUAK_DEFAULT_SCOPE",
        default = "https://storage.azure.com/.default"
      ),
      community_repo = list(
        value = NULL,
        env = "QUAK_COMMUNITY_REPO",
        default = "https://community-extensions.duckdb.org"
      ),
      collect_verbose = list(
        value = NULL,
        env = "QUAK_COLLECT_VERBOSE",
        type = "logical",
        default = TRUE
      ),
      install_verbose = list(
        value = NULL,
        env = "QUAK_INSTALL_VERBOSE",
        type = "logical",
        default = TRUE
      ),
      default_exts = list(
        value = NULL,
        env = "QUAK_DEFAULT_EXTS",
        default = c("httpfs", "azure", "delta")
      ),
      startup_repo_check = list(
        value = NULL,
        env = "QUAK_STARTUP_REPO_CHECK",
        type = "logical",
        default = TRUE
      )
    ),
    parent = emptyenv()
  )

  .sentinel <- new.env(parent = emptyenv())

  coerce <- function(name, value) {
    spec <- .spec[[name]]
    type <- spec$type
    if (is.null(type)) {
      return(value)
    }

    if (type == "logical") {
      if (rlang::is_bool(value)) {
        return(value)
      }
      if (rlang::is_string(value)) {
        value <- tolower(value)
        if (value %in% c("true", "t", "1", "yes", "y")) {
          return(TRUE)
        }
        if (value %in% c("false", "f", "0", "no", "n")) {
          return(FALSE)
        }
      }
      abort_invalid_option(name, spec$env)
    }

    abort_unknown_opt_type(name, type)
  }

  # Resolve a name to its value and the source it came from, following the
  # precedence value -> options(quak.*) -> env var -> built-in default.
  resolve <- function(name) {
    spec <- .spec[[name]]
    if (!is.null(spec$value)) {
      return(list(value = coerce(name, spec$value), source = "set"))
    }
    opt <- getOption(paste0("quak.", name), NULL)
    if (!is.null(opt)) {
      return(list(value = coerce(name, opt), source = "option"))
    }
    env <- Sys.getenv(spec$env, unset = "")
    if (nzchar(env)) {
      return(list(value = coerce(name, env), source = "envvar"))
    }
    list(value = coerce(name, spec$default), source = "default")
  }

  get <- function(name, default = .sentinel) {
    spec <- .spec[[name]]
    if (is.null(spec)) {
      abort_unknown_option(name, ls(.spec))
    }
    res <- resolve(name)
    if (res$source == "default" && !identical(default, .sentinel)) {
      return(default)
    }
    res$value
  }

  set <- function(name, value = NULL) {
    if (is.null(.spec[[name]])) {
      abort_unknown_option(name, ls(.spec))
    }
    entry <- .spec[[name]]
    entry$value <- value
    .spec[[name]] <- entry
    invisible(value)
  }

  reset <- function() {
    for (nm in ls(.spec)) {
      entry <- .spec[[nm]]
      entry$value <- NULL
      .spec[[nm]] <- entry
    }
    invisible(NULL)
  }

  # Resolved view of every option: its current value, where that value came
  # from, the env var that can override it (and its raw value), and the
  # built-in default. Values are formatted to a single string for display —
  # multi-valued options (e.g. default_exts) are comma-joined, unset is NA.
  format_value <- function(v) {
    if (is.null(v) || length(v) == 0L) {
      return(NA_character_)
    }
    paste(as.character(v), collapse = ", ")
  }
  list_all <- function() {
    names <- ls(.spec)
    res <- lapply(names, resolve)
    env_vars <- vapply(names, function(n) .spec[[n]]$env, character(1))
    env_raw <- Sys.getenv(env_vars, unset = NA_character_)
    try_as_tibble(data.frame(
      option = names,
      value = vapply(res, function(r) format_value(r$value), character(1)),
      source = vapply(res, `[[`, character(1), "source"),
      env_var = unname(env_vars),
      env_value = unname(env_raw),
      default = unname(vapply(
        names,
        function(n) format_value(.spec[[n]]$default),
        character(1)
      ))
    ))
  }

  structure(
    list(
      get = get,
      set = set,
      reset = reset,
      list = list_all,
      .names = ls(.spec)
    ),
    class = "quak_opts"
  )
})

# Replace the value/env_value/default of sensitive options with "<hidden>".
mask_quak_opts <- function(tbl, mask) {
  if (!mask) {
    return(tbl)
  }
  sensitive <- character()
  for (col in c("value", "env_value", "default")) {
    hit <- tbl$option %in% sensitive & !is.na(tbl[[col]])
    tbl[[col]][hit] <- "<hidden>"
  }
  tbl
}

#' Print the quak option registry
#'
#' Renders one row per option with its current (resolved) value, the source
#' that value came from, the environment variable that can override it (and
#' whether it is set), and the built-in default.
#'
#' @param x A `quak_opts` object (the internal `opts` registry).
#' @param mask Logical. When `TRUE` (default), sensitive option values are
#'   shown as `"<hidden>"` when set.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @exportS3Method base::print
print.quak_opts <- function(x, mask = TRUE, ...) {
  out <- mask_quak_opts(x$list(), mask)

  # Unset values render as a grey "(not set)"; set values are styled as {.val}.
  fmt_field <- function(v) {
    if (is.na(v)) {
      cli::col_grey("(not set)")
    } else {
      cli::format_inline("{.val {v}}")
    }
  }

  cli::cli_h1("quak options")
  for (i in seq_len(nrow(out))) {
    option <- out$option[[i]]
    source <- out$source[[i]]
    value <- fmt_field(out$value[[i]])
    env_var <- out$env_var[[i]]
    env_value <- fmt_field(out$env_value[[i]])

    # Values straight from the built-in default get a grey "(default)" marker
    # rather than a redundant line repeating the default.
    suffix <- if (source == "default") {
      cli::col_grey("(default)")
    } else {
      cli::format_inline("{.emph [{source}]}")
    }

    # Render verbatim (not via cli_text) so long values aren't reflowed onto a
    # second line when they exceed the console width.
    cli::cli_verbatim(
      cli::format_inline("{.field {option}} = {value} {suffix}")
    )
    cli::cli_verbatim(
      cli::format_inline("  {.envvar {env_var}}: {env_value}")
    )
  }

  invisible(x)
}

#' List all quak options and their current values
#'
#' Prints every quak option (via [print.quak_opts()]) and invisibly returns a
#' tibble of the same information. The resolution order is: value set via
#' `options(quak.*)` -> the option's env var -> a built-in default.
#'
#' @param mask Logical. When `TRUE` (default), sensitive option values are
#'   shown as `"<hidden>"` when set.
#' @return Invisibly, a [tibble::tibble()] with columns `option`, `value`,
#'   `source`, `env_var`, `env_value`, and `default`.
#' @examples
#' quak_options()
#' @export
quak_options <- function(mask = TRUE) {
  if (!rlang::is_bool(mask)) {
    abort_bad_arg(
      "{.arg mask} must be `TRUE` or `FALSE`.",
      arg = "mask",
      value = mask
    )
  }
  print(opts, mask = mask)
  invisible(mask_quak_opts(opts$list(), mask))
}
