# Print the quak option registry

Renders one row per option with its current (resolved) value, the source
that value came from, the environment variable that can override it (and
whether it is set), and the built-in default.

## Usage

``` r
# S3 method for class 'quak_opts'
print(x, mask = TRUE, ...)
```

## Arguments

- x:

  A `quak_opts` object (the internal `opts` registry).

- mask:

  Logical. When `TRUE` (default), sensitive option values are shown as
  `"<hidden>"` when set.

- ...:

  Unused.

## Value

Invisibly returns `x`.
