# Extracted from test-tables.R:143

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "quak", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
local_tagged_tbl <- function(conn, name = "demo", env = parent.frame()) {
  DBI::dbWriteTable(conn, name, data.frame(a = 1:3, b = letters[1:3]))
  new_tbl_az(dplyr::tbl(conn, name))
}

# test -------------------------------------------------------------------------
conn <- local_ext_conn()
expect_error(
    tbl_json(conn, "not-a-url"),
    "Azure Data Lake",
    class = "quak_error_invalid_azure_url"
  )
