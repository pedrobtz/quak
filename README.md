# quak

<!-- badges: start -->
[![PackageVersion](https://www.r-pkg.org/badges/version/quak)](https://www.r-pkg.org/pkg/quak)
[![R-CMD-check](https://github.com/pedrobtz/quak/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pedrobtz/quak/actions/workflows/R-CMD-check.yaml)
[![coverage](https://raw.githubusercontent.com/pedrobtz/quak/main/.github/badges/coverage.svg)](https://github.com/pedrobtz/quak/actions/workflows/coverage.yaml)
<!-- badges: end -->

`quak` provides convenient utilities for using DuckDB with datasets stored in
Azure Data Lake Storage Gen2 (`abfss://`). It opens connections configured for
Azure-backed Delta Lake, Parquet, CSV and JSON data, registers Azure
credentials as DuckDB secrets, writes results back to the lake, and manages
DuckDB extensions for restricted networks. It works with both SQL via DBI and
lazy table queries via dplyr and dbplyr.

## Installation

Install the released version from CRAN:

```r
install.packages("quak")
```

Or install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("pedrobtz/quak")
```

## Connect and authenticate

Start by opening an Azure-ready DuckDB connection. `az_conn()` installs and
loads the `azure` and `delta` extensions but registers no credentials, so
follow it with one of the secret helpers.

```r
library(quak)

conn <- az_conn()
```

Use a credential chain when you want DuckDB to resolve credentials itself, for
example from the Azure CLI:

```r
az_set_chain_secret(conn, chain = "cli")
```

Use an access token when another package obtains the token for you:

```r
az_creds <- azr::DefaultCredential$new(
  scope = az_default_scope()
)

az_set_token_secret(conn, token = az_creds$get_token()$access_token)
```

Use a service principal when you want to pass the application credentials
directly:

```r
az_set_sp_secret(
  conn,
  tenant_id = Sys.getenv("AZURE_TENANT_ID"),
  client_id = Sys.getenv("AZURE_CLIENT_ID"),
  client_secret = Sys.getenv("AZURE_CLIENT_SECRET")
)
```

All secret helpers also accept `account = "storageaccount"` to scope the secret
to one storage account. `az_list_secrets()` shows what is registered, and
`az_tune()` adjusts DuckDB's Azure transport settings such as concurrency and
chunk size.

## Query with SQL

Use `load_delta()` to register a Delta table in DuckDB and query it with SQL.
The default `method = "attach"` attaches the table; `method = "view"` creates
a view instead. `version` and `timestamp` select an earlier snapshot.

```r
conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")

load_delta(
  conn = conn,
  url = "abfss://container@account/path/sales",
  name = "sales"
)

DBI::dbGetQuery(
  conn,
  "SELECT COUNT(*) AS n, AVG(amount) AS avg_amount
   FROM sales
   WHERE amount > 100"
)

DBI::dbDisconnect(conn, shutdown = TRUE)
```

`load_parquet()`, `load_csv()` and `load_json()` do the same for other
formats, and `load_dataset()` dispatches on a `format` argument.

## Query with dplyr

Use `tbl_delta()` when you want to work with a Delta table through
dplyr/dbplyr. `collect()` checks that the connection is still open and the
`azure` extension is loaded before the query runs.

```r
conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")

sales <- tbl_delta(conn, "abfss://container@account/path/sales")

sales |>
  dplyr::filter(amount > 100) |>
  dplyr::summarise(avg_amount = mean(amount, na.rm = TRUE)) |>
  dplyr::collect()
```

`tbl_parquet()`, `tbl_csv()` and `tbl_json()` open the other formats as lazy
tables. `tbl_parquet()` accepts `hive_partitioning = TRUE` for partitioned
directories.

```r
events <- tbl_parquet(
  conn,
  "abfss://container@account/path/events/*.parquet",
  hive_partitioning = TRUE
)
```

## Inspect and write data on the lake

A few helpers look at what is on the lake without collecting it:

```r
az_exists(conn, "abfss://container@account/path/sales")
az_glob(conn, "abfss://container@account/path/**/*.parquet")
az_schema(conn, "abfss://container@account/path/sales")
az_glimpse(conn, "abfss://container@account/path/sales", n = 5)
az_delta_files(conn, "abfss://container@account/path/sales")
```

`az_copy_to()` writes a lazy table, data frame or SQL query back to the lake
with DuckDB's `COPY ... TO`. `az_write_parquet()` is the Parquet shortcut.

```r
az_write_parquet(
  conn,
  sales |> dplyr::filter(amount > 100),
  "abfss://container@account/path/sales_large",
  partition_by = "region",
  overwrite = TRUE
)

DBI::dbDisconnect(conn, shutdown = TRUE)
```

## Extensions in restricted networks

DuckDB fetches extensions from the internet on first use. On machines that
cannot reach the default repositories, point quak at a mirror and keep a local
cache of extension files.

```r
repo_set_urls(
  core = "https://mirror.example.com/duckdb/core",
  community = "https://mirror.example.com/duckdb/community"
)

ext_install("azure")
ext_load("delta")
ext_list_installed()
```

`repo_set_urls()` stores the URLs in the `quak.core_repo` and
`quak.community_repo` options, so they can be set once in `.Rprofile`.
`ext_cache_path()` and `ext_set_dir()` control where cached extensions live,
and `ext_install_local()` installs from a file. `quak_options()` prints every
option quak reads, with its environment variable and current value.
