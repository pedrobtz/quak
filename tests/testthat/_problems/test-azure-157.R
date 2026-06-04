# Extracted from test-azure.R:157

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "quak", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
skip_on_cran()
skip_on_os("windows")
conn <- local_ext_conn()
az_conn(
    token = "fake-token-for-testing",
    accounts = c("acctone", "accttwo"),
    conn = conn
  )
