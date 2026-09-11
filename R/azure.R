#' Get the default Azure OAuth scope
#'
#' Returns the Azure OAuth scope used in examples and token-based authentication
#' helpers. Configure it with `options(quak.default_scope = "...")` or the
#' `QUAK_DEFAULT_SCOPE` environment variable.
#'
#' @return A character scalar OAuth scope.
#' @examples
#' az_default_scope()
#' @export
az_default_scope <- function() {
  opts$get("default_scope")
}

#' Open a DuckDB connection configured for Azure Data Lake Storage Gen2
#'
#' Opens a DuckDB connection and installs the `azure` and `delta` extensions.
#' No secret is registered — use [az_set_token_secret()], [az_set_sp_secret()],
#' or [az_set_chain_secret()] to supply credentials afterwards.
#'
#' @param conn An existing DuckDB connection to configure. When `NULL`
#'   (default) a new in-memory connection is opened via [conn_open()].
#' @return A DuckDB connection. The caller owns its lifetime; disconnect with
#'   `DBI::dbDisconnect(conn, shutdown = TRUE)`.
#' @export
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn() |>
#'   az_set_token_secret(token = my_token)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' }
az_conn <- function(conn = NULL) {
  if (is.null(conn)) {
    conn <- conn_open()
  }

  ext_install("httpfs", conn = conn, verbose = FALSE)
  ext_load("azure", conn = conn)
  ext_load("delta", conn = conn)

  conn_setting(conn, "azure_transport_option_type", "curl")

  conn
}


#' Get Azure settings from a DuckDB connection
#'
#' Queries `duckdb_settings()` and returns all entries whose name contains
#' `"azure"`.
#'
#' @param conn A DuckDB connection. Defaults to [az_conn()].
#' @return A [tibble::tibble()] with columns `name`, `value`, `description`.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' az_conn_settings(conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
az_conn_settings <- function(conn = az_conn()) {
  try_as_tibble(DBI::dbGetQuery(
    conn,
    "SELECT name, value, description
     FROM duckdb_settings()
     WHERE name LIKE '%azure%'"
  ))
}

#' List Azure secrets registered in DuckDB
#'
#' Queries `duckdb_secrets()` and returns secrets whose `type` is `"azure"`.
#' Values are returned as DuckDB reports them; DuckDB handles redaction of
#' sensitive fields.
#'
#' @param conn A DuckDB connection. Defaults to [conn_default()].
#' @return A [tibble::tibble()] with the columns returned by
#'   `duckdb_secrets()`.
#' @examples
#' conn <- DBI::dbConnect(duckdb::duckdb())
#' az_list_secrets(conn)
#' DBI::dbDisconnect(conn, shutdown = TRUE)
#' @export
az_list_secrets <- function(conn = conn_default()) {
  try_as_tibble(DBI::dbGetQuery(
    conn,
    "SELECT *
     FROM duckdb_secrets()
     WHERE type = 'azure'
     ORDER BY name"
  ))
}


#' Register an Azure token secret
#'
#' Creates or replaces a DuckDB Azure secret using the `access_token` provider.
#' Use this when another package has already obtained an access token and you
#' want to register or refresh a token secret.
#'
#' @param conn A DuckDB connection.
#' @param token Character scalar. Access token value.
#' @param account Optional storage account name. When supplied, the secret is
#'   scoped to `abfss://<account>/`.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_set_token_secret(conn, token = "<access-token>")
#' }
#' @export
az_set_token_secret <- function(
  conn,
  token,
  account = NULL
) {
  check_required_arg(token, "token")
  if (!rlang::is_string(token) || !nzchar(token)) {
    abort_invalid_az_secret(
      "{.arg token} must be a non-empty character scalar.",
      arg = "token",
      account = account
    )
  }

  secret_name <- az_secret_name(account)
  scope_clause <- az_secret_scope_clause(account, conn)

  sql <- glue::glue_sql(
    "CREATE OR REPLACE SECRET {secret_name} (
      TYPE azure,
      PROVIDER access_token,
      ACCESS_TOKEN {token}
      {scope_clause}
    )",
    .con = conn
  )
  DBI::dbExecute(conn, sql)

  msgs <- if (is.null(account)) {
    c("v" = "Azure access token secret registered.")
  } else {
    c(
      "v" = "Azure access token secret registered for account {.val {account}}."
    )
  }
  cli::cli_inform(msgs)

  invisible(conn)
}

#' Register an Azure service-principal secret
#'
#' Creates or replaces a DuckDB Azure secret using the `service_principal`
#' provider.
#'
#' @param conn A DuckDB connection.
#' @param tenant_id Character scalar. Azure Entra tenant ID.
#' @param client_id Character scalar. Service principal client ID.
#' @param client_secret Character scalar. Service principal client secret.
#' @param account Optional storage account name. When supplied, the secret is
#'   scoped to that account.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_set_sp_secret(
#'   conn,
#'   tenant_id = "00000000-0000-0000-0000-000000000000",
#'   client_id = Sys.getenv("AZURE_CLIENT_ID"),
#'   client_secret = Sys.getenv("AZURE_CLIENT_SECRET")
#' )
#' }
#' @export
az_set_sp_secret <- function(
  conn,
  tenant_id,
  client_id,
  client_secret,
  account = NULL
) {
  az_check_secret_value(tenant_id, "tenant_id")
  az_check_secret_value(client_id, "client_id")
  az_check_secret_value(client_secret, "client_secret")

  secret_name <- az_secret_name(account)
  account_clause <- az_secret_account_clause(account, conn)
  scope_clause <- az_secret_scope_clause(account, conn)

  sql <- glue::glue_sql(
    "CREATE OR REPLACE SECRET {secret_name} (
      TYPE azure,
      PROVIDER service_principal,
      TENANT_ID {tenant_id},
      CLIENT_ID {client_id},
      CLIENT_SECRET {client_secret}
      {account_clause}
      {scope_clause}
    )",
    .con = conn
  )
  DBI::dbExecute(conn, sql)

  if (is.null(account)) {
    cli::cli_inform(c("v" = "Azure service principal secret registered."))
  } else {
    cli::cli_inform(c(
      "v" = "Azure service principal secret registered for account {.val {account}}."
    ))
  }

  invisible(conn)
}

#' Register an Azure credential-chain secret
#'
#' Creates or replaces a DuckDB Azure secret using the `credential_chain`
#' provider. This lets DuckDB resolve credentials itself, for example from the
#' Azure CLI or environment.
#'
#' @param conn A DuckDB connection.
#' @param account Optional storage account name. When supplied, the secret is
#'   scoped to that account.
#' @param chain Optional character vector of DuckDB credential-chain entries.
#'   Values are joined with semicolons and passed as DuckDB's `CHAIN` value.
#'   Defaults to `"default"`, DuckDB's default credential chain.
#' @return Invisibly returns `conn`.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_set_chain_secret(conn, chain = "cli")
#' }
#' @export
az_set_chain_secret <- function(
  conn,
  account = NULL,
  chain = "default"
) {
  if (!is.null(chain)) {
    if (!is.character(chain) || anyNA(chain) || !all(nzchar(chain))) {
      abort_invalid_az_secret(
        "{.arg chain} must be a character vector with non-empty values.",
        arg = "chain",
        account = account
      )
    }
    chain <- paste(chain, collapse = ";")
  }

  secret_name <- az_secret_name(account)
  chain_clause <- az_secret_chain_clause(chain, conn)
  account_clause <- az_secret_account_clause(account, conn)
  scope_clause <- az_secret_scope_clause(account, conn)

  sql <- glue::glue_sql(
    "CREATE OR REPLACE SECRET {secret_name} (
      TYPE azure,
      PROVIDER credential_chain
      {chain_clause}
      {account_clause}
      {scope_clause}
    )",
    .con = conn
  )
  DBI::dbExecute(conn, sql)

  if (is.null(account)) {
    cli::cli_inform(c("v" = "Azure credential chain secret registered."))
  } else {
    cli::cli_inform(c(
      "v" = "Azure credential chain secret registered for account {.val {account}}."
    ))
  }

  invisible(conn)
}

az_secret_name <- function(account = NULL) {
  if (is.null(account)) {
    return(DBI::SQL("quak_default"))
  }
  if (!rlang::is_string(account) || !nzchar(account)) {
    abort_invalid_az_secret(
      "{.arg account} must be a non-empty character scalar or {.code NULL}.",
      arg = "account",
      account = account
    )
  }
  DBI::SQL(paste0("quak_", gsub("[^a-zA-Z0-9]", "_", account)))
}

az_secret_account_clause <- function(account, conn) {
  if (is.null(account)) {
    return(DBI::SQL(""))
  }
  glue::glue_sql(",\n      ACCOUNT_NAME {account}", .con = conn)
}

az_secret_scope_clause <- function(account, conn) {
  if (is.null(account)) {
    return(DBI::SQL(""))
  }
  scopes <- az_account_scopes(account)
  glue::glue_sql(",\n      SCOPE ({scopes*})", .con = conn)
}

#' Secret scopes matching an Azure storage account
#'
#' DuckDB matches secret scopes as plain string prefixes against the raw URL,
#' with no normalisation. An account-derived scope therefore has to name the
#' account's host, which differs per scheme: `abfss://`/`abfs://` address the
#' ADLS endpoint, `az://`/`azure://` the Blob endpoint.
#'
#' @param account Character scalar. Storage account name, either bare
#'   (`"myaccount"`) or fully qualified (`"myaccount.dfs.core.windows.net"`).
#' @return Character vector of scope prefixes, each with a trailing slash.
#' @keywords internal
az_account_scopes <- function(account) {
  if (grepl(".", account, fixed = TRUE)) {
    # Already a fully qualified host; use it verbatim for every scheme.
    return(paste0(c("abfss://", "abfs://", "az://", "azure://"), account, "/"))
  }
  c(
    paste0(c("abfss://", "abfs://"), account, ".dfs.core.windows.net/"),
    paste0(c("az://", "azure://"), account, ".blob.core.windows.net/")
  )
}

az_secret_chain_clause <- function(chain, conn) {
  if (is.null(chain)) {
    return(DBI::SQL(""))
  }
  glue::glue_sql(",\n      CHAIN {chain}", .con = conn)
}

az_check_secret_value <- function(value, arg) {
  if (!rlang::is_string(value) || !nzchar(value)) {
    abort_invalid_az_secret(
      "{.arg {arg}} must be a non-empty character scalar.",
      arg = arg
    )
  }
  invisible(value)
}
