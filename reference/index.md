# Package index

## Connections and Azure credentials

- [`az_conn()`](https://pedrobtz.github.io/quak/reference/az_conn.md) :
  Open a DuckDB connection configured for Azure Data Lake Storage Gen2
- [`az_conn_settings()`](https://pedrobtz.github.io/quak/reference/az_conn_settings.md)
  : Get Azure settings from a DuckDB connection
- [`az_default_scope()`](https://pedrobtz.github.io/quak/reference/az_default_scope.md)
  : Get the default Azure OAuth scope
- [`az_list_secrets()`](https://pedrobtz.github.io/quak/reference/az_list_secrets.md)
  : List Azure secrets registered in DuckDB
- [`az_set_chain_secret()`](https://pedrobtz.github.io/quak/reference/az_set_chain_secret.md)
  : Register an Azure credential-chain secret
- [`az_set_sp_secret()`](https://pedrobtz.github.io/quak/reference/az_set_sp_secret.md)
  : Register an Azure service-principal secret
- [`az_set_token_secret()`](https://pedrobtz.github.io/quak/reference/az_set_token_secret.md)
  : Register an Azure token secret
- [`az_tune()`](https://pedrobtz.github.io/quak/reference/az_tune.md) :
  Tune Azure read settings on a DuckDB connection
- [`conn_setting()`](https://pedrobtz.github.io/quak/reference/conn_setting.md)
  : Get or set DuckDB settings

## Lazy tables and registered datasets

- [`tbl_delta()`](https://pedrobtz.github.io/quak/reference/tbl_delta.md)
  : Open a Delta Lake table as a lazy dplyr tbl
- [`tbl_parquet()`](https://pedrobtz.github.io/quak/reference/tbl_parquet.md)
  : Open a Parquet dataset as a lazy dplyr tbl
- [`tbl_csv()`](https://pedrobtz.github.io/quak/reference/tbl_csv.md) :
  Open a CSV dataset as a lazy dplyr tbl
- [`tbl_json()`](https://pedrobtz.github.io/quak/reference/tbl_json.md)
  : Open a JSON dataset as a lazy dplyr tbl
- [`collect(`*`<tbl_az>`*`)`](https://pedrobtz.github.io/quak/reference/collect.tbl_az.md)
  : Collect an Azure-backed lazy tbl
- [`load_dataset()`](https://pedrobtz.github.io/quak/reference/load_dataset.md)
  : Register a Delta, Parquet, CSV, or JSON dataset on a DuckDB
  connection
- [`load_delta()`](https://pedrobtz.github.io/quak/reference/load_delta.md)
  : Register a Delta Lake table on a DuckDB connection
- [`load_parquet()`](https://pedrobtz.github.io/quak/reference/load_parquet.md)
  : Register a Parquet dataset as a view on a DuckDB connection
- [`load_csv()`](https://pedrobtz.github.io/quak/reference/load_csv.md)
  : Register a CSV dataset as a view on a DuckDB connection
- [`load_json()`](https://pedrobtz.github.io/quak/reference/load_json.md)
  : Register a JSON dataset as a view on a DuckDB connection

## Azure lake operations

- [`az_copy_to()`](https://pedrobtz.github.io/quak/reference/az_copy_to.md)
  : Copy data to Azure Data Lake Storage Gen2
- [`az_write_parquet()`](https://pedrobtz.github.io/quak/reference/az_write_parquet.md)
  : Write Parquet data to Azure Data Lake Storage Gen2
- [`az_glob()`](https://pedrobtz.github.io/quak/reference/az_glob.md) :
  List Azure paths matching a glob pattern
- [`az_exists()`](https://pedrobtz.github.io/quak/reference/az_exists.md)
  : Check whether data exists at an Azure path
- [`az_schema()`](https://pedrobtz.github.io/quak/reference/az_schema.md)
  : Inspect a dataset schema without collecting data
- [`az_glimpse()`](https://pedrobtz.github.io/quak/reference/az_glimpse.md)
  : Preview an Azure dataset
- [`az_delta_files()`](https://pedrobtz.github.io/quak/reference/az_delta_files.md)
  : List files in a Delta table on Azure Data Lake Storage Gen2

## Extension repositories and cache

- [`ext_cache()`](https://pedrobtz.github.io/quak/reference/ext_cache.md)
  : Extension cache
- [`ext_cache_path()`](https://pedrobtz.github.io/quak/reference/ext_cache_path.md)
  : Default DuckDB extension cache directory
- [`ext_dir()`](https://pedrobtz.github.io/quak/reference/ext_dir.md) :
  Find the DuckDB extension folder
- [`ext_install()`](https://pedrobtz.github.io/quak/reference/ext_install.md)
  : Install a DuckDB extension
- [`ext_install_local()`](https://pedrobtz.github.io/quak/reference/ext_install_local.md)
  : Install a DuckDB extension from a local file
- [`ext_is_installed()`](https://pedrobtz.github.io/quak/reference/ext_is_installed.md)
  : Check whether a DuckDB extension is installed
- [`ext_list_available()`](https://pedrobtz.github.io/quak/reference/ext_list_available.md)
  : List all DuckDB core extensions
- [`ext_list_installed()`](https://pedrobtz.github.io/quak/reference/ext_list_installed.md)
  : List installed DuckDB extensions
- [`ext_load()`](https://pedrobtz.github.io/quak/reference/ext_load.md)
  : Load a DuckDB extension, installing it first if necessary
- [`ext_set_dir()`](https://pedrobtz.github.io/quak/reference/ext_set_dir.md)
  : Set the DuckDB extension folder
- [`ext_uninstall()`](https://pedrobtz.github.io/quak/reference/ext_uninstall.md)
  : Uninstall a DuckDB extension
- [`repo_set_urls()`](https://pedrobtz.github.io/quak/reference/repo_set_urls.md)
  : Set DuckDB extension repository URLs
- [`repo_urls()`](https://pedrobtz.github.io/quak/reference/repo_urls.md)
  : Get DuckDB extension repository URLs
- [`quak_options()`](https://pedrobtz.github.io/quak/reference/quak_options.md)
  : List all quak options and their current values
- [`print(`*`<quak_opts>`*`)`](https://pedrobtz.github.io/quak/reference/print.quak_opts.md)
  : Print the quak option registry
