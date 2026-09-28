.onAttach <- function(libname, pkgname) {
  if (rlang::is_interactive()) {
    repo_startup_check()
  }
}
