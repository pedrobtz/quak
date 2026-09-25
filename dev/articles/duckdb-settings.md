# DuckDB connection settings

Every quak connection is a DuckDB database. DuckDB picks its defaults
for a single user on their own machine: it uses most of the memory and
every CPU core. That works well on a laptop. On a shared server, in a
container, or for very large queries, a few settings are worth changing.

This article covers DuckDB’s settings. quak also has its own options,
such as the extension cache directory and whether `collect()` prints
progress. Those are separate. See
[`quak_options()`](https://pedrobtz.github.io/quak/dev/reference/quak_options.md).

## The settings that matter most

| Setting | Default | Change it to |
|----|----|----|
| `memory_limit` | 80% of RAM | Leave memory for R and other programs |
| `threads` | One per CPU core | Share the machine, or fit a container |
| `temp_directory` | Inside R’s temporary directory | Put overflow data on a large disk |
| `max_temp_directory_size` | 90% of free disk space | Cap how much disk overflow data uses |
| `preserve_insertion_order` | `true` | Make large writes use less memory |

### `memory_limit`

`memory_limit` caps the memory DuckDB uses. It does not include R’s own
memory, and the data frames that `collect()` returns live in R. With the
default of 80%, DuckDB and R together can run the machine out of memory.
On a shared server or in a container, the operating system may then stop
the process.

A lower limit leaves room for R. When a query needs more than the limit,
DuckDB writes intermediate data to disk instead of failing. This works
for joins, aggregations, sorts and window functions.

### `threads`

`threads` is the number of threads DuckDB runs queries on. Lower it on a
machine that other people or jobs share. Inside a container, check the
value with `conn_setting(conn, "threads")`. Depending on how the
container limits CPU, DuckDB may see more cores than it is allowed to
use. Each thread also holds its own buffers, so fewer threads use less
memory.

There is a trade-off for quak. Reading from Azure is mostly waiting for
the network, and more threads keep more requests going at once. Lowering
`threads` can make large scans slower.

### `temp_directory` and `max_temp_directory_size`

`temp_directory` is where DuckDB writes intermediate data when a query
goes over `memory_limit`. By default it is inside R’s temporary
directory. On Linux servers and in containers that directory is often on
a small `/tmp` disk, and a large join fails once the disk is full. Point
it at a disk with plenty of free space.

`max_temp_directory_size` caps how much space that directory may use.

A low `memory_limit` only prevents crashes if DuckDB has somewhere to
put the overflow, so set these together.

### `preserve_insertion_order`

By default, DuckDB returns rows in the order they were read, even when
the query has no `ORDER BY`. To keep that order, it must hold data back
in memory. Setting `preserve_insertion_order` to `false` lets DuckDB
process and write data in parallel, with much less memory. It helps most
for large writes with
[`az_copy_to()`](https://pedrobtz.github.io/quak/dev/reference/az_copy_to.md),
[`az_write_parquet()`](https://pedrobtz.github.io/quak/dev/reference/az_write_parquet.md)
and `CREATE TABLE ... AS SELECT`.

Queries without `ORDER BY` can then return rows in any order. Add
[`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html)
wherever order matters.

## Set them when you open the connection

Pass the settings to
[`duckdb::duckdb()`](https://r.duckdb.org/reference/duckdb.html) as a
`config` list, then give the connection to
[`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md).
Write every value as a string:

``` r

library(quak)

conn <- DBI::dbConnect(duckdb::duckdb(config = list(
  memory_limit = "4GB",
  threads = "4",
  temp_directory = "/scratch/duckdb",
  preserve_insertion_order = "false"
)))

conn <- az_conn(conn)
az_set_chain_secret(conn, chain = "cli")
```

## Change them on an open connection

[`conn_setting()`](https://pedrobtz.github.io/quak/dev/reference/conn_setting.md)
changes a setting on a connection that is already open:

``` r

conn <- az_conn()

conn_setting(conn, "memory_limit", "4GB")
#> ✔ Set `memory_limit` = "4GB"
conn_setting(conn, "threads", 4)
#> ✔ Set `threads` = 4
conn_setting(conn, "temp_directory", "/scratch/duckdb")
#> ✔ Set `temp_directory` = "/scratch/duckdb"
conn_setting(conn, "preserve_insertion_order", FALSE)
#> ✔ Set `preserve_insertion_order` = FALSE
```

With just a name, it returns the current value as a string:

``` r

conn_setting(conn, "threads")
#> [1] "4"
```

With no name, it returns every setting, with a description of each:

``` r

settings <- conn_setting(conn)
settings[settings$name %in% c("memory_limit", "threads"), c("name", "value")]
#> # A tibble: 2 × 2
#>   name         value
#>   <chr>        <chr>
#> 1 memory_limit 3.7 GiB
#> 2 threads      4
```

DuckDB reports sizes in binary units. `"4GB"` is 4 × 10⁹ bytes, which it
shows as 3.7 GiB.

To go back to the default, reset the setting:

``` r

DBI::dbExecute(conn, "RESET threads")
```

## Settings apply to the whole database

These settings belong to the database, not to one connection. When
several connections share one `duckdb()` driver, they share one
database, and a change made on any of them applies to all:

``` r

drv <- duckdb::duckdb()
conn1 <- DBI::dbConnect(drv)
conn2 <- DBI::dbConnect(drv)

conn_setting(conn1, "threads", 3)
conn_setting(conn2, "threads")
#> [1] "3"
```

Each call to
[`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md)
without an existing connection opens a new database, with its own
settings.

## Azure read settings

[`az_tune()`](https://pedrobtz.github.io/quak/dev/reference/az_tune.md)
sets how DuckDB reads from Azure. Each argument left as `NULL` keeps its
current value:

``` r

az_tune(conn, concurrency = 8, metadata_cache = TRUE)
```

| Argument | DuckDB setting | What it controls |
|----|----|----|
| `concurrency` | `azure_read_transfer_concurrency` | How many transfer requests one read makes at once |
| `chunk_size` | `azure_read_transfer_chunk_size` | The size of each transfer request |
| `buffer_size` | `azure_read_buffer_size` | The size of the read buffer |
| `transport` | `azure_transport_option_type` | The HTTP library used. [`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md) sets `"curl"` |
| `metadata_cache` | `enable_http_metadata_cache` | Whether file metadata is cached between queries |
| `context_cache` | `azure_context_caching` | Whether the Azure connection context is reused |

[`az_tune()`](https://pedrobtz.github.io/quak/dev/reference/az_tune.md)
warns when `buffer_size` is not a whole multiple of `chunk_size`.
[`az_conn_settings()`](https://pedrobtz.github.io/quak/dev/reference/az_conn_settings.md)
lists every Azure setting and its current value.

## Examples

### A shared server or a container

Cap memory and threads, and put overflow data on a large disk:

``` r

conn <- DBI::dbConnect(duckdb::duckdb(config = list(
  memory_limit = "8GB",
  threads = "4",
  temp_directory = "/scratch/duckdb",
  max_temp_directory_size = "100GB"
)))
conn <- az_conn(conn)
```

### A large export

Turn off insertion order before writing a large result back to the lake:

``` r

conn_setting(conn, "preserve_insertion_order", FALSE)

az_write_parquet(
  conn,
  tbl_delta(conn, "abfss://container@account/path/events"),
  "abfss://container@account/path/events_parquet",
  partition_by = "event_date"
)
```

### Use the same settings every session

DuckDB settings last as long as the connection. To use the same settings
every time, wrap them in a small function in your project or
`.Rprofile`:

``` r

my_conn <- function() {
  conn <- DBI::dbConnect(duckdb::duckdb(config = list(
    memory_limit = "8GB",
    threads = "4"
  )))
  conn <- az_conn(conn)
  az_set_chain_secret(conn, chain = "cli")
  conn
}
```
