## Update submission

This is an update from 0.1.1 to 0.1.2. It fixes one bug: quak connections
now turn off DuckDB's automatic extension installation
(`autoinstall_known_extensions`) unless the user sets it. DuckDB 2.0 turns it
on by default, so a query could download the 'azure' or 'delta' extension
without going through quak's configured extension repository.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local macOS, R release
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel,
  release, oldrel-1)
