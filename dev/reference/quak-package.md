# quak: Query 'Azure Data Lake Storage Gen2' with 'DuckDB'

Provides convenience utilities for using 'DuckDB' directly over datasets
stored in 'Azure Data Lake Storage Gen2' (ADLS Gen2, 'abfss://'). Opens
connections configured for Azure-backed 'Delta Lake' and 'Parquet' data,
registers Azure credentials as 'DuckDB' secrets, and supports optional
repository mirrors for restricted networks. Integrates well with 'DBI'
for SQL workflows and with 'dplyr' and 'dbplyr' for lazy table queries.

## See also

Useful links:

- <https://github.com/pedrobtz/quak>

- Report bugs at <https://github.com/pedrobtz/quak/issues>

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]
