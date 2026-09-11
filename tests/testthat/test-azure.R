test_that("az_conn installs extensions and returns connection", {
  skip_on_cran()
  # The azure/delta extensions are not published for the R/mingw Windows
  # platform (windows_amd64_mingw), so DuckDB's INSTALL 404s there.
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  result <- az_conn(conn = conn)
  expect_true(inherits(result, "duckdb_connection"))
  expect_true(ext_is_installed("azure", conn))
  expect_true(ext_is_installed("delta", conn))
})

test_that("az_default_scope returns the configured default scope", {
  withr::with_envvar(
    c(QUAK_DEFAULT_SCOPE = "https://example.test/.default"),
    expect_equal(az_default_scope(), "https://example.test/.default")
  )
})

test_that("az_set_token_secret registers a default secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(
    az_set_token_secret(
      conn,
      account = NULL,
      token = "fake-token-for-testing"
    )
  )
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_default" %in% secrets$name)
})

test_that("az_set_token_secret registers a scoped secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(
    az_set_token_secret(
      conn,
      account = "myaccount",
      token = "fake-token-for-testing"
    )
  )
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_myaccount" %in% secrets$name)
})

test_that("az_set_token_secret sanitises account names", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  az_set_token_secret(conn, account = "my-account.name", token = "tok")
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_my_account_name" %in% secrets$name)
})

test_that("az_list_secrets lists registered azure secrets", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  az_set_token_secret(
    conn,
    account = "myaccount",
    token = "fake-token-for-testing"
  )

  secrets <- az_list_secrets(conn)

  expect_s3_class(secrets, "tbl_df")
  expect_true("quak_myaccount" %in% secrets$name)
  expect_equal(secrets$type[secrets$name == "quak_myaccount"], "azure")
  expect_equal(
    secrets$provider[secrets$name == "quak_myaccount"],
    "access_token"
  )
  expect_true("secret_string" %in% names(secrets))
})

test_that("az_set_sp_secret registers a default secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(
    az_set_sp_secret(
      conn,
      tenant_id = "test-tenant",
      client_id = "test-client",
      client_secret = "test-secret"
    )
  )
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_default" %in% secrets$name)
})

test_that("az_set_sp_secret registers a scoped secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(
    az_set_sp_secret(
      conn,
      account = "myaccount",
      tenant_id = "test-tenant",
      client_id = "test-client",
      client_secret = "test-secret"
    )
  )
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_myaccount" %in% secrets$name)
})

test_that("az_set_chain_secret registers a default secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(az_set_chain_secret(conn))
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_default" %in% secrets$name)
})

test_that("az_set_chain_secret registers a scoped secret", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  expect_no_error(
    az_set_chain_secret(
      conn,
      account = "myaccount",
      chain = c("cli", "env")
    )
  )
  secrets <- DBI::dbGetQuery(conn, "SELECT name FROM duckdb_secrets()")
  expect_true("quak_myaccount" %in% secrets$name)
})

# Secret scopes ----------------------------------------------------------------

test_that("az_account_scopes covers the documented account-host URL forms", {
  expect_equal(
    az_account_scopes("myaccount"),
    c(
      "abfss://myaccount.dfs.core.windows.net/",
      "abfs://myaccount.dfs.core.windows.net/",
      "az://myaccount.blob.core.windows.net/",
      "azure://myaccount.blob.core.windows.net/"
    )
  )
})

test_that("az_account_scopes accepts an already-qualified host", {
  expect_equal(
    az_account_scopes("myaccount.dfs.core.windows.net"),
    c(
      "abfss://myaccount.dfs.core.windows.net/",
      "abfs://myaccount.dfs.core.windows.net/",
      "az://myaccount.dfs.core.windows.net/",
      "azure://myaccount.dfs.core.windows.net/"
    )
  )
})

test_that("an account-scoped secret is selected for that account's URLs", {
  # Regression: the scope used to be abfss://<account>/, which matched nothing.
  # DuckDB matches scopes as raw string prefixes, so only an execution test
  # against which_secret() can catch this.
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  az_set_token_secret(conn, account = "myaccount", token = "fake-token")

  matches <- function(url) {
    nrow(DBI::dbGetQuery(
      conn,
      glue::glue_sql("SELECT * FROM which_secret({url}, 'azure')", .con = conn)
    )) > 0L
  }

  expect_true(matches("abfss://myaccount.dfs.core.windows.net/c/f.parquet"))
  expect_true(matches("az://myaccount.blob.core.windows.net/c/f.parquet"))
  # quak normalises this form to the account-host form before querying.
  expect_true(matches(
    check_azure_url("abfss://c@myaccount/f.parquet")
  ))
})

test_that("an account-scoped secret is not selected for another account", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_offline()
  conn <- local_ext_conn()
  ext_install("azure", conn = conn)
  az_set_token_secret(conn, account = "myaccount", token = "fake-token")

  found <- DBI::dbGetQuery(
    conn,
    "SELECT * FROM which_secret(
       'abfss://otheraccount.dfs.core.windows.net/c/f.parquet', 'azure')"
  )
  expect_equal(nrow(found), 0L)
})
