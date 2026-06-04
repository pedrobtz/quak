# quak

<!-- badges: start -->
[![R-CMD-check](https://github.com/pedrobtz/quak/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pedrobtz/quak/actions/workflows/R-CMD-check.yaml)
[![coverage](https://raw.githubusercontent.com/pedrobtz/quak/main/.github/badges/coverage.svg)](https://github.com/pedrobtz/quak/actions/workflows/coverage.yaml)
<!-- badges: end -->

`quak` provides convenient utilities for using DuckDB with datasets stored in
Azure Data Lake Storage Gen2 (`abfss://`). It opens connections configured for
Azure-backed Delta Lake data, registers Azure credentials as DuckDB secrets, and
works with both SQL via DBI and lazy table queries via dplyr and dbplyr.

## Installation

`quak` is not yet on CRAN. Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("pedrobtz/quak")
```

## Connect and authenticate

Start by opening an Azure-ready DuckDB connection. Then register one Azure
secret on that connection.

```r
library(quak)

conn <- az_conn()
```

Use a credential chain when you want DuckDB to resolve credentials itself, for
example from the Azure CLI:

```r
library(quak)

conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")
```

Use an access token when another package obtains the token for you:

```r
library(quak)

az_creds <- azr::DefaultCredential$new(
  scope = az_default_scope()
)

conn <- az_conn()
az_set_token_secret(conn, token = az_creds$get_token()$access_token)
```

Use a service principal when you want to pass the application credentials
directly:

```r
library(quak)

conn <- az_conn()
az_set_sp_secret(
  conn,
  tenant_id = Sys.getenv("AZURE_TENANT_ID"),
  client_id = Sys.getenv("AZURE_CLIENT_ID"),
  client_secret = Sys.getenv("AZURE_CLIENT_SECRET")
)
```

All secret helpers also accept `account = "storageaccount"` to scope the secret
to one storage account.

## Register a Delta table

Use `load_delta()` when you want to register a Delta table in DuckDB and query
it with SQL.

```r
library(quak)

conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")

load_delta(
  conn = conn,
  url = "abfss://container@account/path/sales",
  name = "sales",
  method = "view"
)

DBI::dbGetQuery(
  conn,
  "SELECT COUNT(*) AS n, AVG(amount) AS avg_amount
   FROM sales
   WHERE amount > 100"
)

DBI::dbDisconnect(conn, shutdown = TRUE)
```

## Use a lazy table

Use `tbl_delta()` when you want to work with a Delta table through dplyr/dbplyr.

```r
library(quak)

conn <- az_conn()
az_set_chain_secret(conn, chain = "cli")

sales <- tbl_delta(conn, "abfss://container@account/path/sales")

sales |>
  dplyr::filter(amount > 100) |>
  dplyr::summarise(avg_amount = mean(amount, na.rm = TRUE)) |>
  dplyr::collect()

DBI::dbDisconnect(conn, shutdown = TRUE)
```
