# Decompress a gzip file to a destination path

Streams `src` (a gzip-compressed file) through
[`gzfile()`](https://rdrr.io/r/base/connections.html) into `dest`, fully
closing both connections before returning. Closing the output connection
flushes R's internal buffer to disk; skipping that step can leave the
trailing bytes — where a `.duckdb_extension` stores its metadata footer
— unwritten, yielding a corrupt file.

## Usage

``` r
gunzip_file(src, dest)
```

## Arguments

- src:

  Character scalar. Path to the gzip-compressed source file.

- dest:

  Character scalar. Path to write the decompressed output to.

## Value

Invisibly returns `dest`.
