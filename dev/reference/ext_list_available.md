# List all DuckDB core extensions

Returns the full catalog of extensions maintained by the DuckDB core
team, regardless of whether they are installed.

## Usage

``` r
ext_list_available(conn = conn_default())
```

## Arguments

- conn:

  A DuckDB connection. Defaults to
  [`conn_default()`](https://pedrobtz.github.io/quak/dev/reference/conn_default.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns: `name`, `version`, `description`.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpVpZTOE/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
ext_list_available(conn)
#> # A tibble: 30 × 3
#>    name           version description                                           
#>    <chr>          <chr>   <chr>                                                 
#>  1 autocomplete   ""      Adds support for autocomplete in the shell            
#>  2 avro           ""      Adds support for reading Avro files                   
#>  3 aws            ""      Provides features that depend on the AWS SDK          
#>  4 azure          ""      Adds a filesystem abstraction for Azure blob storage …
#>  5 core_functions ""      Core function library                                 
#>  6 delta          ""      Adds support for Delta Lake                           
#>  7 ducklake       ""      Adds support for DuckLake, SQL as a Lakehouse Format  
#>  8 encodings      ""      All unicode encodings to UTF-8                        
#>  9 excel          ""      Adds support for Excel-like format strings            
#> 10 fts            ""      Adds support for Full-Text Search Indexes             
#> # ℹ 20 more rows
DBI::dbDisconnect(conn, shutdown = TRUE)
```
