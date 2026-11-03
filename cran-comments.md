## Update submission

This is an update from 0.1.1 to 0.1.2. It fixes one bug: quak connections
now turn off DuckDB's automatic extension installation
(`autoinstall_known_extensions`) unless the user sets it. DuckDB 2.0 turns it
on by default, so a query could download the 'azure' or 'delta' extension
without going through quak's configured extension repository.

This also fixes the test ERROR that 0.1.1 shows on the CRAN check page
(r-devel-linux-x86_64-debian-clang, r-devel-linux-x86_64-debian-gcc,
r-devel-linux-x86_64-fedora-gcc, r-patched-linux-x86_64,
r-release-linux-x86_64, and the M1mac additional check). Under duckdb 2.0.0
the test 'az_tune is quiet and wraps DuckDB setting failures' downloaded the
'azure' extension instead of failing as expected.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local macOS, R release
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel,
  release, oldrel-1)
