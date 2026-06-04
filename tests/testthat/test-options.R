test_that("unknown option errors with informative message", {
  expect_error(opts$get("nonexistent"), class = "quak_error_unknown_option")
  expect_error(opts$get("nonexistent"), regexp = "nonexistent")
})

test_that("set value takes precedence over env var and default", {
  local_opt("cache_dir", "/from-set")
  withr::local_options(quak.cache_dir = "/from-option")
  withr::with_envvar(
    c(QUAK_CACHE_DIR = "/from-env-var"),
    expect_equal(opts$get("cache_dir"), "/from-set")
  )
})

test_that("option takes precedence over env var and default", {
  local_opt("cache_dir", NULL)
  withr::local_options(quak.cache_dir = "/from-option")
  withr::with_envvar(
    c(QUAK_CACHE_DIR = "/from-env-var"),
    expect_equal(opts$get("cache_dir"), "/from-option")
  )
})

test_that("env var takes precedence over default", {
  local_opt("cache_dir", NULL)
  withr::local_options(quak.cache_dir = NULL)
  withr::with_envvar(
    c(QUAK_CACHE_DIR = "/from-env-var"),
    expect_equal(opts$get("cache_dir"), "/from-env-var")
  )
})

test_that("default is returned when neither value nor env var is set", {
  local_opt("core_repo", NULL)
  withr::with_envvar(
    c(QUAK_CORE_REPO = NA),
    expect_equal(opts$get("core_repo"), "https://extensions.duckdb.org")
  )
})

test_that("cache_dir default is derived from tools::R_user_dir", {
  opts$reset()
  local_opt("cache_dir", NULL)
  withr::local_options(quak.cache_dir = NULL)
  withr::with_envvar(
    c(QUAK_CACHE_DIR = NA),
    expect_equal(opts$get("cache_dir"), tools::R_user_dir("quak", "cache"))
  )
})

test_that("community_repo has correct default", {
  local_opt("community_repo", NULL)
  withr::with_envvar(
    c(QUAK_COMMUNITY_REPO = NA),
    expect_equal(
      opts$get("community_repo"),
      "https://community-extensions.duckdb.org"
    )
  )
})

test_that("default_scope has correct default", {
  local_opt("default_scope", NULL)
  withr::with_envvar(
    c(QUAK_DEFAULT_SCOPE = NA),
    expect_equal(
      opts$get("default_scope"),
      "https://storage.azure.com/.default"
    )
  )
})

test_that("collect_verbose has correct default", {
  local_opt("collect_verbose", NULL)
  withr::with_envvar(
    c(QUAK_COLLECT_VERBOSE = NA),
    expect_true(opts$get("collect_verbose"))
  )
})

test_that("install_verbose has correct default", {
  local_opt("install_verbose", NULL)
  withr::with_envvar(
    c(QUAK_INSTALL_VERBOSE = NA),
    expect_true(opts$get("install_verbose"))
  )
})

test_that("empty env var string falls through to default", {
  local_opt("core_repo", NULL)
  withr::with_envvar(
    c(QUAK_CORE_REPO = ""),
    expect_equal(opts$get("core_repo"), "https://extensions.duckdb.org")
  )
})

test_that("default_exts default is a character vector", {
  local_opt("default_exts", NULL)
  withr::with_envvar(
    c(QUAK_DEFAULT_EXTS = NA),
    expect_equal(opts$get("default_exts"), c("httpfs", "azure", "delta"))
  )
})

test_that("opts$reset clears all in-memory values", {
  opts$set("core_repo", "https://custom.example.com")
  opts$reset()
  withr::with_envvar(
    c(QUAK_CORE_REPO = NA),
    expect_equal(opts$get("core_repo"), "https://extensions.duckdb.org")
  )
})

test_that("set with unknown option errors with informative message", {
  expect_error(
    opts$set("nonexistent", "x"),
    class = "quak_error_unknown_option"
  )
  expect_error(opts$set("nonexistent", "x"), regexp = "nonexistent")
})

test_that("get custom default overrides spec default when neither value nor env var is set", {
  local_opt("core_repo", NULL)
  withr::with_envvar(
    c(QUAK_CORE_REPO = NA),
    expect_null(opts$get("core_repo", default = NULL))
  )
})

test_that("collect_verbose accepts env var booleans", {
  local_opt("collect_verbose", NULL)
  withr::with_envvar(
    c(QUAK_COLLECT_VERBOSE = "false"),
    expect_false(opts$get("collect_verbose"))
  )
  withr::with_envvar(
    c(QUAK_COLLECT_VERBOSE = "true"),
    expect_true(opts$get("collect_verbose"))
  )
})

test_that("install_verbose accepts env var booleans", {
  local_opt("install_verbose", NULL)
  withr::with_envvar(
    c(QUAK_INSTALL_VERBOSE = "false"),
    expect_false(opts$get("install_verbose"))
  )
  withr::with_envvar(
    c(QUAK_INSTALL_VERBOSE = "true"),
    expect_true(opts$get("install_verbose"))
  )
})

test_that("collect_verbose rejects invalid values", {
  local_opt("collect_verbose", "maybe")
  expect_error(
    opts$get("collect_verbose"),
    "collect_verbose",
    class = "quak_error_invalid_option"
  )
})

test_that("install_verbose rejects invalid values", {
  local_opt("install_verbose", "maybe")
  expect_error(
    opts$get("install_verbose"),
    "install_verbose",
    class = "quak_error_invalid_option"
  )
})

test_that("quak_options returns one row per option with resolved value and source", {
  opts$reset()
  out <- withr::with_envvar(
    c(QUAK_CORE_REPO = "https://mirror.example"),
    quak_options()
  )
  expect_s3_class(out, "tbl_df")
  expect_setequal(out$option, opts$.names)
  expect_named(
    out,
    c("option", "value", "source", "env_var", "env_value", "default")
  )

  core <- out[out$option == "core_repo", ]
  expect_equal(core$source, "envvar")
  expect_equal(core$value, "https://mirror.example")
  expect_equal(core$default, "https://extensions.duckdb.org")
})

test_that("quak_options mask is a no-op without sensitive options", {
  out <- quak_options()
  unmasked <- quak_options(mask = FALSE)
  expect_equal(out, unmasked)
})

test_that("quak_options validates mask", {
  expect_error(
    quak_options(mask = "x"),
    "TRUE",
    class = "quak_error_bad_argument"
  )
})

test_that("quak_options returns the tibble invisibly", {
  expect_invisible(quak_options())
})
