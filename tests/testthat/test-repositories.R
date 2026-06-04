test_that("repo_ext_url assembles the download URL", {
  expect_equal(
    repo_ext_url(
      "https://extensions.duckdb.org",
      "v1.2.0",
      "osx_arm64",
      "httpfs"
    ),
    "https://extensions.duckdb.org/v1.2.0/osx_arm64/httpfs.duckdb_extension.gz"
  )
})

test_that("repo_urls returns core and community defaults", {
  withr::defer(opts$reset())
  opts$reset()
  withr::with_envvar(c(QUAK_CORE_REPO = NA, QUAK_COMMUNITY_REPO = NA), {
    urls <- repo_urls()
    expect_named(urls, c("core", "community"))
    expect_equal(urls$core, "https://extensions.duckdb.org")
    expect_equal(urls$community, "https://community-extensions.duckdb.org")
  })
})

test_that("repo_set_urls updates and resets repository URLs", {
  withr::defer(opts$reset())
  res <- repo_set_urls(
    core = "https://core.example",
    community = "https://comm.example",
    check = FALSE
  )
  expect_equal(res$core, "https://core.example")
  expect_equal(res$community, "https://comm.example")
  expect_equal(repo_urls()$core, "https://core.example")

  repo_set_urls(core = NULL, check = FALSE)
  withr::with_envvar(
    c(QUAK_CORE_REPO = NA),
    expect_equal(repo_urls()$core, "https://extensions.duckdb.org")
  )
})

test_that("repo_set_urls sets and resets the DuckDB core repository", {
  withr::defer(opts$reset())
  conn <- local_ext_conn()

  repo_set_urls(core = "https://core.example", check = FALSE, conn = conn)
  expect_equal(
    conn_setting(conn, "custom_extension_repository"),
    "https://core.example"
  )

  repo_set_urls(core = NULL, check = FALSE, conn = conn)
  expect_equal(conn_setting(conn, "custom_extension_repository"), "")
})

test_that("repo_set_urls validates inputs", {
  withr::defer(opts$reset())
  expect_error(
    repo_set_urls(core = 1L),
    "character scalar",
    class = "quak_error_bad_argument"
  )
  expect_error(
    repo_set_urls(community = 1L),
    "character scalar",
    class = "quak_error_bad_argument"
  )
})

test_that("repo_set_urls omitting an argument leaves the other unchanged", {
  withr::defer(opts$reset())
  repo_set_urls(
    core = "https://core.example",
    community = "https://comm.example",
    check = FALSE
  )

  repo_set_urls(core = "https://core2.example", check = FALSE)
  expect_equal(repo_urls()$community, "https://comm.example")

  repo_set_urls(community = "https://comm2.example", check = FALSE)
  expect_equal(repo_urls()$core, "https://core2.example")
})

test_that("repo_set_urls with check = TRUE calls repo_check for changed repos", {
  withr::defer(opts$reset())
  conn <- local_ext_conn()
  checked <- character()
  local_mocked_bindings(
    repo_check = function(repo, ...) {
      checked <<- c(checked, repo)
      invisible(c(httpfs = TRUE))
    }
  )
  repo_set_urls(core = "https://core.example", check = TRUE, conn = conn)
  expect_equal(checked, "core")

  checked <- character()
  repo_set_urls(community = "https://comm.example", check = TRUE, conn = conn)
  expect_equal(checked, "community")

  checked <- character()
  repo_set_urls(
    core = "https://c.example",
    community = "https://d.example",
    check = TRUE,
    conn = conn
  )
  expect_setequal(checked, c("core", "community"))
})

test_that("repo_check returns FALSE for unreachable extensions", {
  conn <- local_ext_conn()
  local_mocked_bindings(repo_head_ok = function(url) FALSE)
  ok <- repo_check("core", ext = "httpfs", conn = conn)
  expect_false(ok[["httpfs"]])
})

test_that("repo_check returns TRUE for reachable extensions", {
  conn <- local_ext_conn()
  local_mocked_bindings(repo_head_ok = function(url) TRUE)
  ok <- repo_check("core", ext = "httpfs", conn = conn)
  expect_true(ok[["httpfs"]])
})

test_that("repo_set_urls aborts when check fails", {
  withr::defer(opts$reset())
  conn <- local_ext_conn()
  local_mocked_bindings(repo_head_ok = function(url) FALSE)
  expect_error(
    repo_set_urls(core = "https://fake.example", check = TRUE, conn = conn),
    "repository check failed",
    class = "quak_error_repo_check_failed"
  )
})

test_that("repo_check rejects invalid repo argument", {
  conn <- local_ext_conn()
  expect_error(repo_check("invalid", ext = "httpfs", conn = conn))
})

test_that("repo_check rejects non-character ext", {
  conn <- local_ext_conn()
  expect_error(repo_check("core", ext = 1L, conn = conn), "character vector")
})

test_that("repo_check rejects empty ext vector", {
  conn <- local_ext_conn()
  expect_error(
    repo_check("core", ext = character(0), conn = conn),
    "character vector"
  )
})
