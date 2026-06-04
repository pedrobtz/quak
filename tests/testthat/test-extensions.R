test_that("ext_install installs an extension", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  ext_install("json", conn = conn)

  expect_true(ext_is_installed("json", conn))
})

test_that("ext_install is idempotent", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  ext_install("json", conn = conn)
  expect_no_error(ext_install("json", conn = conn))
  expect_true(ext_is_installed("json", conn))
})

test_that("ext_uninstall removes an extension", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  ext_install("json", conn = conn)
  ext_uninstall("json", conn = conn)

  expect_false(ext_is_installed("json", conn))
})

test_that("ext_uninstall on missing extension does not error", {
  conn <- local_ext_conn()

  expect_no_error(ext_uninstall("json", conn = conn))
})

test_that("extension can be reinstalled after uninstall", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  ext_install("json", conn = conn)
  ext_uninstall("json", conn = conn)
  ext_install("json", conn = conn)

  expect_true(ext_is_installed("json", conn))
})

test_that("ext_install_manual reinstalls from cache without network", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()
  info <- conn_info(conn)

  # install via SQL to obtain a real extension file
  ext_install("json", conn = conn)
  real_file <- fs::path(
    ext_dir(conn),
    info$version,
    info$platform,
    "json.duckdb_extension"
  )

  # seed a fresh cache with that file
  cache <- ext_cache(withr::local_tempdir())
  cache$add("json", info$version, info$platform, real_file)

  # uninstall, then reinstall from cache (no network call)
  ext_uninstall("json", conn = conn)
  expect_false(ext_is_installed("json", conn))

  ext_install_manual("json", cache = cache, conn = conn)
  expect_true(ext_is_installed("json", conn))
})

test_that("ext_install falls back to manual when SQL install fails", {
  conn <- local_ext_conn()
  manual_called <- FALSE
  local_mocked_bindings(
    ext_install_sql = function(...) stop("simulated SQL failure"),
    ext_install_manual = function(...) {
      manual_called <<- TRUE
      invisible(conn)
    }
  )
  expect_message(
    ext_install("json", conn = conn),
    "manual install"
  )
  expect_true(manual_called)
})

test_that("ext_install fallback is silent when verbose = FALSE", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    ext_install_sql = function(...) stop("simulated SQL failure"),
    ext_install_manual = function(...) invisible(conn)
  )
  expect_no_message(ext_install("json", conn = conn, verbose = FALSE))
})

test_that("ext_install fallback respects install_verbose", {
  conn <- local_ext_conn()
  old <- opts$get("install_verbose")
  opts$set("install_verbose", FALSE)
  withr::defer(opts$set("install_verbose", old))
  local_mocked_bindings(
    ext_install_sql = function(...) stop("simulated SQL failure"),
    ext_install_manual = function(...) invisible(conn)
  )

  expect_no_message(ext_install("json", conn = conn))
})

test_that("ext_install errors only when both SQL and manual fail", {
  conn <- local_ext_conn()
  local_mocked_bindings(
    ext_install_sql = function(...) stop("simulated SQL failure"),
    ext_install_manual = function(...) stop("simulated manual failure")
  )
  expect_error(
    ext_install("json", conn = conn),
    "Failed to install extension",
    class = "quak_error_extension_install_failed"
  )
})

test_that("ext_install removes SQL leftovers before manual fallback", {
  conn <- local_ext_conn()
  ext_file <- ext_installed_file("leftover", conn)
  local_mocked_bindings(
    ext_install_sql = function(...) {
      fs::dir_create(fs::path_dir(ext_file))
      writeLines("partial", ext_file)
      stop("simulated SQL failure")
    },
    ext_install_manual = function(...) {
      expect_false(fs::file_exists(ext_file))
      invisible(conn)
    }
  )

  expect_message(
    ext_install("leftover", conn = conn),
    "manual install"
  )
})

test_that("ext_install removes manual leftovers when both strategies fail", {
  conn <- local_ext_conn()
  ext_file <- ext_installed_file("leftover", conn)
  local_mocked_bindings(
    ext_install_sql = function(...) stop("simulated SQL failure"),
    ext_install_manual = function(...) {
      fs::dir_create(fs::path_dir(ext_file))
      writeLines("partial", ext_file)
      stop("simulated manual failure")
    }
  )

  expect_error(
    ext_install("leftover", conn = conn),
    "Failed to install extension",
    class = "quak_error_extension_install_failed"
  )
  expect_false(fs::file_exists(ext_file))
})

test_that("ext_install restores a pre-existing file when both strategies fail", {
  conn <- local_ext_conn()
  ext_file <- ext_installed_file("existing", conn)
  fs::dir_create(fs::path_dir(ext_file))
  writeLines("original", ext_file)

  local_mocked_bindings(
    ext_is_installed = function(...) FALSE,
    ext_install_sql = function(...) {
      writeLines("sql partial", ext_file)
      stop("simulated SQL failure")
    },
    ext_install_manual = function(...) {
      writeLines("manual partial", ext_file)
      stop("simulated manual failure")
    }
  )

  expect_error(
    ext_install("existing", conn = conn),
    "Failed to install extension",
    class = "quak_error_extension_install_failed"
  )
  expect_equal(readLines(ext_file), "original")
})

test_that("ext_install does not call manual when SQL succeeds", {
  conn <- local_ext_conn()
  manual_called <- FALSE
  local_mocked_bindings(
    ext_install_sql = function(...) invisible(conn),
    ext_install_manual = function(...) {
      manual_called <<- TRUE
      invisible(conn)
    }
  )
  ext_install("json", conn = conn)
  expect_false(manual_called)
})

test_that("ext_install validates verbose", {
  conn <- local_ext_conn()
  expect_error(ext_install("json", conn = conn, verbose = "x"), "TRUE")
})

test_that("ext_install_manual removes a newly downloaded cache entry on install failure", {
  conn <- local_ext_conn()
  info <- conn_info(conn)
  cache <- ext_cache(withr::local_tempdir())
  src <- withr::local_tempfile(fileext = ".duckdb_extension")
  writeLines("downloaded", src)

  local_mocked_bindings(
    ext_download = function(name, repo, cache, conn) {
      path <- fs::path(
        cache$.path,
        info$version,
        info$platform,
        paste0(name, ".duckdb_extension")
      )
      fs::dir_create(fs::path_dir(path))
      fs::file_copy(src, path)
      path
    },
    file_copy_atomic = function(...) stop("copy failed")
  )

  expect_error(
    ext_install_manual("downloaded", cache = cache, conn = conn),
    "copy failed"
  )
  expect_null(cache$get("downloaded", info$version, info$platform))
})

test_that("ext_load is silent when the extension is already loaded", {
  conn <- local_ext_conn()
  load_called <- FALSE

  local_mocked_bindings(
    ext_is_loaded = function(...) TRUE,
    ext_is_installed = function(...) {
      stop("installed state should not be checked")
    },
    ext_load_sql = function(...) {
      load_called <<- TRUE
      invisible(conn)
    }
  )

  expect_silent(ext_load("json", conn = conn, auto_install = FALSE))
  expect_false(load_called)
})

test_that("ext_load reinstalls a corrupt installed extension once", {
  conn <- local_ext_conn()
  cache <- ext_cache(withr::local_tempdir())
  load_calls <- 0L
  uninstalled <- FALSE
  installed <- FALSE

  local_mocked_bindings(
    ext_is_installed = function(...) TRUE,
    ext_load_sql = function(...) {
      load_calls <<- load_calls + 1L
      if (load_calls == 1L) {
        stop(
          "The file is not a DuckDB extension. The metadata at the end of the file is invalid"
        )
      }
      invisible(conn)
    },
    ext_uninstall = function(..., purge_cache = FALSE) {
      uninstalled <<- purge_cache
      invisible(conn)
    },
    ext_install = function(..., verbose = TRUE) {
      installed <<- !verbose
      invisible(conn)
    }
  )

  expect_warning(
    ext_load("json", conn = conn, cache = cache),
    "reinstalling",
    class = "quak_warning_extension_reinstall_corrupt"
  )
  expect_equal(load_calls, 2L)
  expect_true(uninstalled)
  expect_true(installed)
})

test_that("ext_is_loaded reflects DuckDB's loaded extension state", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  expect_false(ext_is_loaded("json", conn))
  ext_install("json", conn = conn)
  expect_false(ext_is_loaded("json", conn))
  ext_load("json", conn = conn, auto_install = FALSE)
  expect_true(ext_is_loaded("json", conn))
})

test_that("gunzip_file round-trips arbitrary bytes including the trailing footer", {
  # Build a payload whose final bytes are distinctive: a corrupted gunzip
  # truncates the tail (where a .duckdb_extension keeps its metadata footer),
  # so the last bytes are exactly what we must verify survive.
  payload <- as.raw(c(
    sample(0:255, 5000, replace = TRUE),
    0xDE,
    0xAD,
    0xBE,
    0xEF
  ))

  src <- withr::local_tempfile(fileext = ".gz")
  con <- gzfile(src, "wb")
  writeBin(payload, con)
  close(con)

  dest <- withr::local_tempfile(fileext = ".bin")
  gunzip_file(src, dest)

  out <- readBin(dest, "raw", n = length(payload) + 100L)
  expect_identical(out, payload)
})

test_that("ext_install_manual produces a loadable extension via the gz download path", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()
  info <- conn_info(conn)
  cache <- ext_cache(withr::local_tempdir())

  # Force the manual download + decompress path, then load to prove the
  # cached/installed file is byte-complete (footer intact).
  ext_install_manual("json", cache = cache, conn = conn)
  expect_true(ext_is_installed("json", conn))
  expect_no_error(ext_load("json", conn = conn, auto_install = FALSE))
})

test_that("ext_install_manual populates the cache on a download miss", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()
  info <- conn_info(conn)
  cache <- ext_cache(withr::local_tempdir())

  expect_null(cache$get("json", info$version, info$platform))

  ext_install_manual("json", cache = cache, conn = conn)

  expect_false(is.null(cache$get("json", info$version, info$platform)))
  expect_equal(nrow(cache$list()), 1L)
})

test_that("ext_list_installed reflects install and uninstall", {
  skip_on_cran()
  skip_if_offline()
  conn <- local_ext_conn()

  ext_install("json", conn = conn)
  expect_true("json" %in% ext_list_installed(conn)$name)

  ext_uninstall("json", conn = conn)
  expect_false("json" %in% ext_list_installed(conn)$name)
})

test_that("ext_is_installed is FALSE for an extension that is not installed", {
  conn <- local_ext_conn()
  expect_false(ext_is_installed("json", conn))
})

test_that("ext_is_installed validates its argument", {
  expect_error(
    ext_is_installed(1L),
    "character scalar",
    class = "quak_error_bad_argument"
  )
})

test_that("ext_set_dir validates its arguments", {
  expect_error(ext_set_dir(123), "non-empty character")
  expect_error(ext_set_dir(""), "non-empty character")
  expect_error(
    ext_set_dir(withr::local_tempdir(), create = "x"),
    "TRUE",
    class = "quak_error_bad_argument"
  )
})

test_that("ext_set_dir and ext_dir round-trip the extension directory", {
  conn <- conn_open()
  withr::defer(DBI::dbDisconnect(conn, shutdown = TRUE))
  dir <- withr::local_tempdir()
  ext_set_dir(dir, conn)
  expect_equal(fs::path_real(ext_dir(conn)), fs::path_real(dir))
})

test_that("ext_url composes a URL from the configured repo, version, and platform", {
  conn <- local_ext_conn()
  withr::defer(opts$reset())
  repo_set_urls(core = "https://repo.example", check = FALSE)
  url <- ext_url("httpfs", repo = "core", conn = conn)
  expect_match(url, "^https://repo\\.example/")
  expect_match(url, "httpfs\\.duckdb_extension\\.gz$")
})
