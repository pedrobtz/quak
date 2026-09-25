# Default DuckDB extension cache directory

Resolution order: in-memory value (`opts$set("cache_dir", ...)`) -\> env
var `QUAK_CACHE_DIR` -\> OS-appropriate user cache directory via
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

## Usage

``` r
ext_cache_path()
```

## Value

Character scalar. The resolved cache path.

## Examples

``` r
ext_cache_path()
#> [1] "/home/runner/.cache/R/quak"
```
