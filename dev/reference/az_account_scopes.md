# Secret scopes matching an Azure storage account

DuckDB matches secret scopes as plain string prefixes against the raw
URL, with no normalisation. An account-derived scope therefore has to
name the account's host, which differs per scheme: `abfss://`/`abfs://`
address the ADLS endpoint, `az://`/`azure://` the Blob endpoint.

## Usage

``` r
az_account_scopes(account)
```

## Arguments

- account:

  Character scalar. Storage account name, either bare (`"myaccount"`) or
  fully qualified (`"myaccount.dfs.core.windows.net"`).

## Value

Character vector of scope prefixes, each with a trailing slash.
