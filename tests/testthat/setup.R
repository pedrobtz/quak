# duckdb >= 2.0 announces where it keeps extensions and secrets each time a
# driver is created without an explicit location. Choose one for the test
# run so the check log stays readable. Older duckdb ignores the option.
withr::local_options(
  duckdb.home = withr::local_tempdir(.local_envir = testthat::teardown_env()),
  .local_envir = testthat::teardown_env()
)
