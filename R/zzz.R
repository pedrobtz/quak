.cache <- ext_cache()

.onLoad <- function(libname, pkgname) {
  if (rlang::is_interactive()) {
    repo_startup_check()
  }
}
