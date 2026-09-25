# Register an Azure token secret

Creates or replaces a DuckDB Azure secret using the `access_token`
provider. Use this when another package has already obtained an access
token and you want to register or refresh a token secret.

## Usage

``` r
az_set_token_secret(conn, token, account = NULL)
```

## Arguments

- conn:

  A DuckDB connection.

- token:

  Character scalar. Access token value.

- account:

  Optional storage account name. When supplied, the secret is scoped to
  `abfss://<account>/`.

## Value

Invisibly returns `conn`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a live Azure account, credentials, and network access.
conn <- az_conn()
az_set_token_secret(conn, token = "<access-token>")
} # }
```
