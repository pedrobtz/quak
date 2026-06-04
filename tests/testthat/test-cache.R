test_that("ext_cache_path returns a single character path", {
  p <- ext_cache_path()
  expect_type(p, "character")
  expect_length(p, 1L)
})

test_that("ext_cache validates cache_path", {
  expect_error(
    ext_cache(123),
    "character scalar",
    class = "quak_error_bad_argument"
  )
})

test_that("ext_cache returns an ext_cache object", {
  cache <- ext_cache(withr::local_tempdir())
  expect_s3_class(cache, "ext_cache")
})

test_that("ext_cache stores, lists, retrieves, and deletes extensions", {
  cache <- ext_cache(withr::local_tempdir())

  # nothing cached yet
  expect_null(cache$get("azure", "v1.0.0", "linux_amd64"))
  expect_equal(nrow(cache$list()), 0L)

  # add a fake extension file
  src <- withr::local_tempfile(fileext = ".duckdb_extension")
  writeLines("binary", src)
  dest <- cache$add("azure", "v1.0.0", "linux_amd64", src)
  expect_true(fs::file_exists(dest))

  # now retrievable and listed
  expect_false(is.null(cache$get("azure", "v1.0.0", "linux_amd64")))
  listing <- cache$list()
  expect_equal(nrow(listing), 1L)
  expect_equal(listing$name, "azure")
  expect_equal(listing$version, "v1.0.0")
  expect_equal(listing$platform, "linux_amd64")

  # delete
  expect_true(cache$del("azure", "v1.0.0", "linux_amd64"))
  expect_null(cache$get("azure", "v1.0.0", "linux_amd64"))
})

test_that("ext_cache$del on a missing extension returns FALSE", {
  cache <- ext_cache(withr::local_tempdir())
  expect_false(cache$del("azure", "v1.0.0", "linux_amd64"))
})

test_that("ext_cache$add validates src", {
  cache <- ext_cache(withr::local_tempdir())
  expect_error(cache$add("azure", "v1", "linux_amd64", 1L), "character scalar")
  expect_error(
    cache$add("azure", "v1", "linux_amd64", "/no/such/file"),
    "does not exist"
  )
})

test_that("ext_cache_check_key rejects non-string keys", {
  expect_error(ext_cache_check_key(1, "v", "p"), "character scalar")
  expect_error(ext_cache_check_key("n", 1, "p"), "character scalar")
  expect_error(ext_cache_check_key("n", "v", 1), "character scalar")
})

test_that("ext_cache$list returns empty tibble when cache dir does not exist", {
  cache <- ext_cache(file.path(withr::local_tempdir(), "nonexistent"))
  listing <- cache$list()
  expect_equal(nrow(listing), 0L)
  expect_named(listing, c("name", "version", "platform", "size", "modified"))
})

test_that("ext_cache$add overwrites an existing cached entry", {
  cache <- ext_cache(withr::local_tempdir())
  src1 <- withr::local_tempfile(fileext = ".duckdb_extension")
  src2 <- withr::local_tempfile(fileext = ".duckdb_extension")
  writeLines("v1", src1)
  writeLines("v2", src2)
  cache$add("azure", "v1.0.0", "linux_amd64", src1)
  cache$add("azure", "v1.0.0", "linux_amd64", src2)
  path <- cache$get("azure", "v1.0.0", "linux_amd64")
  expect_equal(readLines(path), "v2")
  expect_equal(nrow(cache$list()), 1L)
})

test_that("file_copy_atomic restores an existing destination on failure", {
  dest <- withr::local_tempfile()
  writeLines("old", dest)

  expect_error(
    file_copy_atomic("/no/such/file", dest),
    class = "quak_error_file_copy_failed"
  )
  expect_equal(readLines(dest), "old")
})

test_that("print.ext_cache prints the cache path", {
  dir <- withr::local_tempdir()
  cache <- ext_cache(dir)
  # cli writes to stderr, so capture its output with cli_fmt() rather than
  # expect_output() (which only sees stdout).
  out <- cli::cli_fmt(print(cache))
  expect_match(out, "ext_cache", all = FALSE)
  expect_match(out, basename(dir), all = FALSE)
})
