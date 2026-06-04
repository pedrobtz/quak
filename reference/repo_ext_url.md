# Assemble an extension download URL

Pure URL builder — no I/O, no connection required. Concatenates the
repository base URL, DuckDB version, platform, and extension filename
with `/` (correct for URLs on all platforms).

## Usage

``` r
repo_ext_url(repo_url, version, platform, name)
```

## Arguments

- repo_url:

  Character scalar. Repository base URL.

- version:

  Character scalar. DuckDB version string (e.g. `"v1.2.0"`).

- platform:

  Character scalar. Platform string (e.g. `"osx_arm64"`).

- name:

  Character scalar. Extension name (e.g. `"httpfs"`).

## Value

Character scalar. Full URL to the `.duckdb_extension.gz` file.
