# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Shared conventions

The portfolio’s shared rules are synced into `.claude/shared/` from
`pedrobtz/packages:claude/shared/`. Never edit them here. Where this
file and a shared file disagree, this file wins for this package.

@.claude/shared/workflow.md @.claude/shared/r-package.md
@.claude/shared/ci.md @.claude/shared/correctness.md
@.claude/shared/assurance.md

## What this is

quak is an R package that runs DuckDB directly over Azure Data Lake
Storage Gen2 (`abfss://`). It opens DuckDB connections with the `azure`
and `delta` extensions loaded and registers Azure credentials as DuckDB
secrets. It exposes the lake as SQL relations (`load_*()`), as lazy
dbplyr tables (`tbl_*()`), and as write targets
([`az_copy_to()`](https://pedrobtz.github.io/quak/dev/reference/az_copy_to.md),
[`az_write_parquet()`](https://pedrobtz.github.io/quak/dev/reference/az_write_parquet.md)).
It also manages DuckDB extensions for machines that cannot reach the
default extension repositories.

quak does not obtain Azure tokens. Credentials come from DuckDB’s own
credential chain, a service principal, or a token that the caller gets
elsewhere, for example from `azr` (Suggests only). `dplyr`, `dbplyr` and
`nanoarrow` are also Suggests. Guard every use with
[`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html).

There is no design or roadmap document. `README.md` is the user-facing
tour.

## Current state

Verified 2026-11-04. Version 0.1.2 is on CRAN (published 2026-11-03, tag
and release `0.1.2`). `main` is `0.1.2.9000`.

No bugs are open. Four were fixed in \#6. One of those fixes is
deliberately a refusal rather than a feature:
[`load_delta()`](https://pedrobtz.github.io/quak/dev/reference/load_delta.md)
and
[`tbl_delta()`](https://pedrobtz.github.io/quak/dev/reference/tbl_delta.md)
reject `timestamp`. DuckDB’s `delta` extension accepts a timestamp and
silently ignores it, so only `version` time travel works.

## Versions and dependents

The current version’s parent issue is \#29 (`v0.1.3`). Sibling packages
that depend on this one: none.

## Commands

Beyond the shared commands, run from the package root:

``` sh
Rscript -e 'devtools::test(filter = "tables")'   # one file: test-tables.R
Rscript -e 'lintr::lint_package()'               # config in .lintr
Rscript -e 'covr::package_coverage()'            # CI publishes the badge
```

`air format .` reads its configuration from `air.toml`.

## Architecture

The code is organised in layers. Each layer calls only the layers below
it:

1.  [R/options.R](https://pedrobtz.github.io/quak/dev/R/options.R) holds
    `opts`, the internal registry for every setting. It resolves a value
    in this order: `opts$set()`, then `options(quak.*)`, then the
    `QUAK_*` environment variable, then the built-in default.
    [`quak_options()`](https://pedrobtz.github.io/quak/dev/reference/quak_options.md)
    prints the result.
2.  [R/conditions.R](https://pedrobtz.github.io/quak/dev/R/conditions.R)
    holds `quak_abort()`, `quak_warn()` and one `abort_*()` or
    `warn_*()` helper for each failure.
3.  [R/connection.R](https://pedrobtz.github.io/quak/dev/R/connection.R)
    opens connections
    ([`conn_open()`](https://pedrobtz.github.io/quak/dev/reference/conn_open.md))
    and reads and writes DuckDB settings
    ([`conn_setting()`](https://pedrobtz.github.io/quak/dev/reference/conn_setting.md),
    [`az_tune()`](https://pedrobtz.github.io/quak/dev/reference/az_tune.md)).
4.  [R/cache.R](https://pedrobtz.github.io/quak/dev/R/cache.R),
    [R/repositories.R](https://pedrobtz.github.io/quak/dev/R/repositories.R)
    and
    [R/extensions.R](https://pedrobtz.github.io/quak/dev/R/extensions.R)
    handle extensions.
    [`ext_install()`](https://pedrobtz.github.io/quak/dev/reference/ext_install.md)
    first tries SQL `INSTALL`. If that fails, it downloads the file with
    `curl` from the configured repository into the local cache and
    installs it from there. It snapshots the installed file first, so a
    failed attempt is rolled back.
    [`ext_load()`](https://pedrobtz.github.io/quak/dev/reference/ext_load.md)
    auto-installs a missing extension. If a load fails because the file
    is corrupt, it reinstalls.
5.  [R/azure.R](https://pedrobtz.github.io/quak/dev/R/azure.R) provides
    [`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md)
    and the `az_set_*_secret()` helpers. Secrets are named
    `quak_default` or `quak_<account>`.
6.  [R/datasets.R](https://pedrobtz.github.io/quak/dev/R/datasets.R)
    registers data (`load_*()`). It also holds the shared SQL builders
    (`sql_*_scan()`, `sql_reader_options()`) and
    [`ensure_azure_exts()`](https://pedrobtz.github.io/quak/dev/reference/ensure_azure_exts.md).
    [R/tables.R](https://pedrobtz.github.io/quak/dev/R/tables.R) wraps
    the same scans as `tbl_az` lazy tables, and
    [R/arrow.R](https://pedrobtz.github.io/quak/dev/R/arrow.R) collects
    them as Arrow data.
    [R/lake.R](https://pedrobtz.github.io/quak/dev/R/lake.R) inspects
    and writes files on the lake.
    [R/delta.R](https://pedrobtz.github.io/quak/dev/R/delta.R) lists
    Delta files.

Many functions default to `conn = conn_default()`, which is
[`duckdb::default_conn()`](https://r.duckdb.org/reference/default_conn.html).
Among the Azure helpers, only
[`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md)
installs extensions. The data, table and lake functions call
[`ensure_azure_exts()`](https://pedrobtz.github.io/quak/dev/reference/ensure_azure_exts.md),
which loads with `auto_install = FALSE`. A connection that skipped
[`az_conn()`](https://pedrobtz.github.io/quak/dev/reference/az_conn.md)
therefore fails fast with `quak_error_extension_not_loaded` instead of
downloading anything.

`.onAttach` ([R/zzz.R](https://pedrobtz.github.io/quak/dev/R/zzz.R))
sends HTTP HEAD requests to both extension repositories in interactive
sessions and reports through
[`packageStartupMessage()`](https://rdrr.io/r/base/message.html). It
must never raise. Set `QUAK_STARTUP_REPO_CHECK=false` to disable this.

## Invariants that are easy to break

- **`DESCRIPTION` has a hand-maintained `Collate` field.** No file uses
  `@include`. A new `R/*.R` file must be added to `Collate`, otherwise R
  does not load it. Keep top-level code to definitions. Anything
  evaluated at top level runs when the package is built, on the build
  machine, and depends on the `Collate` order.
- **Use the value that
  [`check_azure_url()`](https://pedrobtz.github.io/quak/dev/reference/check_azure_url.md)
  returns.** It rewrites `abfss://container@account/...` into a form
  DuckDB accepts. DuckDB matches a secret’s `SCOPE` as a plain prefix of
  the URL, so an account-scoped secret only applies to the rewritten URL
  ([`az_account_scopes()`](https://pedrobtz.github.io/quak/dev/reference/az_account_scopes.md)).
  The `delta` extension rejects that form, so every SQL builder that
  calls it (`delta_scan`, `delta_list_files`, `ATTACH ... TYPE DELTA`)
  must pass the URL through
  [`delta_url()`](https://pedrobtz.github.io/quak/dev/reference/delta_url.md).
  Account-scoped secrets never match Delta URLs.
- **Build all SQL with `glue::glue_sql(..., .con = conn)`.** Quote
  identifiers as `` {`name`} ``. The names of reader options are spliced
  in as raw SQL, so `check_reader_options()` restricts them to
  identifier syntax. Do not relax that check without quoting the names
  another way.
- **Every `tbl_*()` constructor must end with
  [`new_tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/new_tbl_az.md).**
  Otherwise
  [`collect.tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/collect.tbl_az.md)
  and its pre-flight checks are skipped.
  [`collect.tbl_az()`](https://pedrobtz.github.io/quak/dev/reference/collect.tbl_az.md)
  hands over with
  [`NextMethod()`](https://rdrr.io/r/base/UseMethod.html), not by
  calling
  [`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
  again. Calling the generic again would restart dispatch and run any
  outer class’s method a second time.
- **Add a setting to the `opts` registry, never read
  [`getOption()`](https://rdrr.io/r/base/options.html) or
  [`Sys.getenv()`](https://rdrr.io/r/base/Sys.getenv.html) directly.**
  Each entry needs an `env` name. Logical entries need
  `type = "logical"` so that string values from environment variables
  are coerced.
- **Raise errors through `abort_*()` helpers.** They add a
  `quak_error_<kind>` class on top of `quak_error`. Add a new helper to
  `conditions.R` rather than calling
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  directly.
- **Exported topics must be listed in
  [\_pkgdown.yml](https://pedrobtz.github.io/quak/dev/_pkgdown.yml).**
  The pkgdown build fails otherwise. Internal functions use
  `@keywords internal` and stay out of the index.

## Testing

- Helpers are in `tests/testthat/helper-*.R`. `local_ext_conn()` opens a
  fresh connection whose extension directory is a temporary directory,
  and closes it on exit. `local_opt()` sets an `opts` entry and restores
  it on exit. Use them rather than the default connection or the user’s
  extension directory.
- Condition classes are `quak_error_<kind>`:
  `expect_error(..., class = "quak_error_<kind>")`.
- No test uses Azure credentials. Tests that download extensions use
  `skip_on_cran()` and `skip_if_offline()`. Tests that need the `azure`
  or `delta` extension also use `skip_on_os("windows")`, because those
  extensions are not published for `windows_amd64_mingw`.
- Mock internal functions with `local_mocked_bindings()`.

## Editing rules

- **Deviation:** there is no `README.Rmd`, so `README.md` is edited
  directly.
- Long-form docs are pkgdown articles in `vignettes/articles/`, not
  vignettes. `.Rbuildignore` excludes `vignettes/`, so they never reach
  CRAN, and their dependencies go in `Config/Needs/website`, not
  Suggests. Their code chunks use `eval = FALSE` because they need
  Azure.
- Examples that reach Azure go in `\dontrun{}` with the comment
  `# Requires a live Azure account, credentials, and network access.`
- `.lintr` allows lines up to 120 characters.

## Releases

The release flow is the shared one in `.claude/shared/workflow.md`. Here
the GitHub release is named `quak <version>` and the bump pull request
is titled `Post-release`. Once CRAN publishes, the daily `CRAN stage`
workflow in `pedrobtz/packages` opens the next `v<version>` issue and
moves the board card to it.

## Continuous integration

`.github/workflows/` contains `R-CMD-check` and `coverage`, which call
the shared `pedrobtz/r-actions` workflows, `cran-release` (r-actions
`cran-release.yml`), and `pkgdown` from the standard `r-lib/actions`
workflows. The R-CMD-check legs are macOS, Windows, and Ubuntu on devel,
release and oldrel-1. Pull requests run the quick profile; add the
`full-ci` label for the full set (all runners plus the CRAN-like R-devel
containers). **Deviation from `ci.md`:** the full set always runs after
merge, because the caller passes `full` for every event but an
unlabelled pull request. The R-devel containers install duckdb as an
r-universe binary through `tools/ci-binaries.R` (the `pre-install` hook)
instead of building it from source. `pkgdown` deploys to
<https://pedrobtz.github.io/quak/>. The `main` ruleset rejects direct
pushes, so the coverage badge is committed to `badges/coverage.svg` on
`gh-pages`. The pkgdown deploy must keep `force: false` and
`clean: false` (or exclude `badges`), otherwise it overwrites or deletes
the badge.
