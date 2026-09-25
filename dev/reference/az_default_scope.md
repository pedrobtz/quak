# Get the default Azure OAuth scope

Returns the Azure OAuth scope used in examples and token-based
authentication helpers. Configure it with
`options(quak.default_scope = "...")` or the `QUAK_DEFAULT_SCOPE`
environment variable.

## Usage

``` r
az_default_scope()
```

## Value

A character scalar OAuth scope.

## Examples

``` r
az_default_scope()
#> [1] "https://storage.azure.com/.default"
```
