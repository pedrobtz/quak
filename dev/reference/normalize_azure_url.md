# Rewrite `container@account` Azure URLs to the account-host form

DuckDB's azure extension documents two ADLS URL forms:
`abfss://container/path` (account supplied by a secret) and
`abfss://account.dfs.core.windows.net/container/path`. The
`abfss://container@account/path` form is not one of them: without a
matching secret DuckDB rejects it with "Cannot identify the storage
account from path", and because the container precedes the account in
the string, no account-derived secret scope can ever match it.

## Usage

``` r
normalize_azure_url(url)
```

## Arguments

- url:

  Character scalar. An `abfss://` or `abfs://` URL.

## Value

The normalised URL.

## Details

Rewriting it here means account-scoped secrets select correctly and the
URL is one DuckDB documents. URLs without an `@` in the authority are
returned unchanged.
