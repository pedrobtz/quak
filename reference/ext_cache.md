# Extension cache

Builds an `ext_cache` object: a list of closures bound to a cache
directory, implementing CRUD over cached `.duckdb_extension` files.
Files are laid out under
`<cache_path>/<version>/<platform>/<name>.duckdb_extension`.

## Usage

``` r
ext_cache(cache_path = ext_cache_path())
```

## Arguments

- cache_path:

  Character scalar. Cache root directory. Defaults to
  [`ext_cache_path()`](https://pedrobtz.github.io/quak/reference/ext_cache_path.md).

## Value

An `ext_cache` object (a list of closures) with elements:

- `.path`: the cache root.

- `get(name, version, platform)`: path to the cached extension, or
  `NULL`.

- `add(name, version, platform, src)`: copies `src` into the cache.

- [`list()`](https://rdrr.io/r/base/list.html): data frame of cached
  extensions.

- `del(name, version, platform)`: removes a cached extension. When
  `version` and `platform` are omitted, removes all cached entries for
  `name`.

## Examples

``` r
cache <- ext_cache(file.path(tempdir(), "quak-cache"))
cache$.path
#> [1] "/tmp/RtmpEtoRyh/quak-cache"
```
