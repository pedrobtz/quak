# Register an Azure service-principal secret

Creates or replaces a DuckDB Azure secret using the `service_principal`
provider.

## Usage

``` r
az_set_sp_secret(conn, tenant_id, client_id, client_secret, account = NULL)
```

## Arguments

- conn:

  A DuckDB connection.

- tenant_id:

  Character scalar. Azure Entra tenant ID.

- client_id:

  Character scalar. Service principal client ID.

- client_secret:

  Character scalar. Service principal client secret.

- account:

  Optional storage account name. When supplied, the secret is scoped to
  that account.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_set_sp_secret(
  conn,
  tenant_id = "00000000-0000-0000-0000-000000000000",
  client_id = Sys.getenv("AZURE_CLIENT_ID"),
  client_secret = Sys.getenv("AZURE_CLIENT_SECRET")
)
} # }
```
