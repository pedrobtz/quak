# Rewrite an account-host Azure URL to the form the `delta` extension reads

The `delta` extension hands the URL to delta-kernel's `object_store`,
which rejects the account-host form
`abfss://account.dfs.core.windows.net/...`. It accepts
`abfss://container@account.dfs.core.windows.net/path`, so every SQL
builder that calls the `delta` extension passes its URL through here.

## Usage

``` r
delta_url(url)
```

## Arguments

- url:

  Character scalar. A URL returned by
  [`check_azure_url()`](https://pedrobtz.github.io/quak/reference/check_azure_url.md).

## Value

The URL in `container@account` form. URLs whose authority has no dot,
such as `abfss://container/path`, are returned unchanged.

## Details

Account-scoped secrets never match the result, because the container
comes before the account. Delta tables therefore need an unscoped
secret.
