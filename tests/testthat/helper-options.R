local_opt <- function(name, value, env = parent.frame()) {
  old <- opts$get(name)
  opts$set(name, value)
  withr::defer(opts$set(name, old), envir = env)
}
