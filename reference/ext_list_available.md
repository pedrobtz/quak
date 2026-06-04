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
  [`conn_default()`](https://pedrobtz.github.io/quak/reference/conn_default.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns: `name`, `version`, `description`.

## Examples

``` r
conn <- DBI::dbConnect(duckdb::duckdb())
ext_list_available(conn)
#> # A tibble: 28 × 3
#>    name           version description                                           
#>    <chr>          <chr>   <chr>                                                 
#>  1 autocomplete   ""      Adds support for autocomplete in the shell            
#>  2 aws            ""      Provides features that depend on the AWS SDK          
#>  3 azure          ""      Adds a filesystem abstraction for Azure blob storage …
#>  4 core_functions ""      Core function library                                 
#>  5 delta          ""      Adds support for Delta Lake                           
#>  6 ducklake       ""      Adds support for DuckLake, SQL as a Lakehouse Format  
#>  7 encodings      ""      All unicode encodings to UTF-8                        
#>  8 excel          ""      Adds support for Excel-like format strings            
#>  9 fts            ""      Adds support for Full-Text Search Indexes             
#> 10 httpfs         ""      Adds support for reading and writing files over a HTT…
#> # ℹ 18 more rows
DBI::dbDisconnect(conn, shutdown = TRUE)
```
