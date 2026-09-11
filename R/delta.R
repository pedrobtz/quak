#' List files in a Delta table on Azure Data Lake Storage Gen2
#'
#' Returns DuckDB's `delta_list_files()` output for a Delta table.
#'
#' @param conn A DuckDB connection.
#' @param url Character scalar. Azure Blob URL pointing to a Delta table.
#' @return A tibble-like data frame with the active file manifest.
#' @examples
#' \dontrun{
#' # Requires a live Azure account, credentials, and network access.
#' conn <- az_conn()
#' az_delta_files(conn, "abfss://container@account/tables/sales")
#' }
#' @export
az_delta_files <- function(conn, url) {
  check_required_arg(conn, "conn")
  check_required_arg(url, "url")
  if (!rlang::is_string(url)) {
    abort_bad_arg(
      "{.arg url} must be a character scalar.",
      arg = "url",
      value = url
    )
  }
  url <- check_azure_url(url)
  ensure_azure_exts(conn, delta = TRUE)
  try_as_tibble(az_query(
    conn,
    sql_delta_files(url, conn),
    url,
    "Failed to list files for Delta table {.val {url}}."
  ))
}

sql_delta_files <- function(url, conn) {
  glue::glue_sql("SELECT * FROM delta_list_files({url})", .con = conn)
}
