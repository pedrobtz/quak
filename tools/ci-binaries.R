# Run by the R-CMD-check workflow (`pre-install`) before it installs the
# dependencies. On R-devel under Linux no repository the jobs use carries
# binaries, so duckdb (an Imports) would be built from source, which takes
# most of the job's time limit. cran.r-universe.dev publishes Linux binaries
# of CRAN's duckdb for R-devel; install that first and the dependency step
# keeps it. Anywhere else this does nothing.
if (
  R.version$status != "Under development (unstable)" ||
    Sys.info()[["sysname"]] != "Linux"
) {
  quit(save = "no")
}
os <- readLines("/etc/os-release")
codename <- sub(".*=", "", grep("^VERSION_CODENAME=", os, value = TRUE))
rv <- paste(R.version$major, sub("[.].*", "", R.version$minor), sep = ".")
repo <- sprintf(
  "https://cran.r-universe.dev/bin/linux/%s-%s/%s/",
  codename,
  R.version$arch,
  rv
)
install.packages("duckdb", repos = repo)
