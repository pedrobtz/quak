## Update submission

This is an update from 0.1.0 to 0.1.1. It:

* fixes the default extension cache directory, which binary builds set to
  the build machine's home directory;
* adds `collect_arrow()` and `stream_arrow()`, which return query results as
  Arrow data;
* rejects the `timestamp` argument of `load_delta()` and `tbl_delta()`,
  which the DuckDB `delta` extension silently ignored.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local macOS, R release
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel,
  release, oldrel-1)
* win-builder (devel)
