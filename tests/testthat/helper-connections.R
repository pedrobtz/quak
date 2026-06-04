local_ext_conn <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  conn <- conn_open()
  withr::defer(DBI::dbDisconnect(conn, shutdown = TRUE), envir = env)
  ext_set_dir(dir, conn)
  conn
}
