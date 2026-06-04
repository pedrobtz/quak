# Pre-flight checks before collecting a `tbl_az`

Aborts when the backing DuckDB connection is closed or the `azure`
extension is not loaded, turning otherwise cryptic collect-time failures
into actionable messages.

## Usage

``` r
check_tbl_az(x, call = rlang::caller_env())
```

## Arguments

- x:

  A `tbl_az`.

- call:

  The calling environment, used for error reporting.

## Value

Invisibly returns `x`.
