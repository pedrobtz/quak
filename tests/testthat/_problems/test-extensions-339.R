# Extracted from test-extensions.R:339

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "quak", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
skip_on_cran()
conn <- local_ext_conn()
info <- conn_info(conn)
cache <- ext_cache(withr::local_tempdir())
ext_install_manual("json", cache = cache, conn = conn)
