# v0.6.2 Linux/R-release CPU evidence artifact.
# This script lives outside tests/ so R CMD check does not execute a timing
# workload on every platform. Semantic acceptance still comes from package
# checks and exact invariants on every supported platform.

library(visualR)

evidence_dir <- "benchmark-evidence"
dir.create(evidence_dir, showWarnings = FALSE, recursive = TRUE)

numeric_evidence <- benchmark_numeric_observers(
  sizes = c(3L, 11L, 31L), reps = 5L, batches = 3L
)
tap_evidence <- benchmark_tap_compiler(
  widths = c(9L, 33L, 65L), levels = 4L,
  reps = 1000L, batches = 3L
)

stopifnot(
  all(numeric_evidence$semantic_authority == "R"),
  all(numeric_evidence$status == "reference_experimental"),
  all(numeric_evidence$median_ms >= 0),
  all(tap_evidence$equivalent_to_r),
  all(tap_evidence$semantic_authority == "R"),
  all(c("r", "c") %in% tap_evidence$engine)
)

utils::write.csv(
  numeric_evidence,
  file.path(evidence_dir, "numeric-observers.csv"),
  row.names = FALSE
)
utils::write.csv(
  tap_evidence,
  file.path(evidence_dir, "tap-compiler.csv"),
  row.names = FALSE
)

report <- c(
  "# visualR v0.6.2 CPU evidence",
  "",
  sprintf("- Generated: %s", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  sprintf("- R: %s", R.version.string),
  sprintf("- Platform: %s", R.version$platform),
  "- Authority: R",
  "- Status: reference_experimental",
  "- Interpretation: runner-specific diagnostic, not a frozen SLA",
  "",
  "## Numeric observers",
  "",
  "```",
  capture.output(print(numeric_evidence, row.names = FALSE)),
  "```",
  "",
  "## R/C99 tap schedule",
  "",
  "```",
  capture.output(print(tap_evidence, row.names = FALSE)),
  "```",
  "",
  "## Session",
  "",
  "```",
  capture.output(sessionInfo()),
  "```"
)
writeLines(report, file.path(evidence_dir, "report.md"), useBytes = TRUE)

cat(paste(report, collapse = "\n"), "\n")
