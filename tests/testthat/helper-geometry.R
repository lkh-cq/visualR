# v0.8 Geometry tests — shared setup.
# `.onLoad_geometry_defaults()` lives in R/geometry_registry.R but is NOT
# wired to a real package .onLoad (that would be a NAMESPACE/package-env
# change, deferred to another batch). Per the task book we invoke it once
# from a testthat helper so the built-in MetricLaw/TransportLaw defaults
# are present before any geometry test runs. testthat auto-sources every
# `helper-*.R` before the test files in this directory.

# Use the package namespace directly: dot-prefixed internals are NOT
# exported, so a bare call fails under load_all(export_all = FALSE) /
# R CMD check --as-cran (the real CI path). Fail closed if missing.
ns <- asNamespace("visualR")
fn <- get0(".onLoad_geometry_defaults", envir = ns, inherits = FALSE)
if (is.null(fn)) stop("v0.8 geometry defaults missing from package namespace",
                      call. = FALSE)
fn()