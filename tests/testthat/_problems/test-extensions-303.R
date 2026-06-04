# Extracted from test-extensions.R:303

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "quak", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
skip_on_cran()
conn <- local_ext_conn()
expect_false(ext_is_loaded("json", conn))
ext_install("json", conn = conn)
