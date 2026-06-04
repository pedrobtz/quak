# Register an Azure credential-chain secret

Creates or replaces a DuckDB Azure secret using the `credential_chain`
provider. This lets DuckDB resolve credentials itself, for example from
the Azure CLI or environment.

## Usage

``` r
az_set_chain_secret(conn, account = NULL, chain = "default")
```

## Arguments

- conn:

  A DuckDB connection.

- account:

  Optional storage account name. When supplied, the secret is scoped to
  that account.

- chain:

  Optional character vector of DuckDB credential-chain entries. Values
  are joined with semicolons and passed as DuckDB's `CHAIN` value.
  Defaults to `"default"`, DuckDB's default credential chain.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")
} # }
```
