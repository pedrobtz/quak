# Validate that a URL is an Azure Data Lake URL

Validate that a URL is an Azure Data Lake URL

## Usage

``` r
check_azure_url(url)
```

## Arguments

- url:

  Character scalar. URL to validate.

## Value

Invisibly returns `NULL`; called for its side effect of aborting when
`url` is not an `abfss://` URL.
