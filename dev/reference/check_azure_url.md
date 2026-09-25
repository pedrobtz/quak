# Validate and normalise an Azure Data Lake URL

Aborts when `url` is not an `abfss://` URL, then rewrites the
`container@account` authority form to the account-host form DuckDB
documents. Always use the returned value rather than the input.

## Usage

``` r
check_azure_url(url)
```

## Arguments

- url:

  Character scalar. URL to validate.

## Value

The normalised URL.
