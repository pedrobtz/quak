local_tagged_tbl <- function(conn, name = "demo", env = parent.frame()) {
  DBI::dbWriteTable(conn, name, data.frame(a = 1:3, b = letters[1:3]))
  new_tbl_az(dplyr::tbl(conn, name))
}

local_arrow_tbl <- function(conn, n = 25L, env = parent.frame()) {
  DBI::dbExecute(
    conn,
    paste0("CREATE TABLE demo AS SELECT i, i * 2 AS j FROM range(", n, ") t(i)")
  )
  local_mocked_bindings(
    check_tbl_az = function(x, ...) invisible(x),
    .env = env
  )
  local_opt("collect_verbose", FALSE, env = env)
  new_tbl_az(dplyr::tbl(conn, "demo"))
}
