# Tag a lazy tbl as Azure-backed

Prepends the `tbl_az` S3 class to a lazy
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) so that
[`collect.tbl_az()`](https://pedrobtz.github.io/quak/reference/collect.tbl_az.md)
can run pre-flight checks before the query is materialised.

## Usage

``` r
new_tbl_az(x)
```

## Arguments

- x:

  A lazy
  [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html).

## Value

`x` with `"tbl_az"` prepended to its class vector.
