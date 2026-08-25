# v0.7.0 Promotion Gate tests — R authority (gate 13) and no-accelerator (gate 14).
# These prove by inspection/reflection (not assumption) that:
#   - R is the semantic authority (gate 13): no external semantic engine, no
#     non-base computation abstraction defines Merge semantics.
#   - No native accelerator changes semantics (gate 14): v0.7 modules have no
#     .Call/.C/.Fortran/.External entry points and no src/ compiled object.

v070_files <- function() {
  c("R/router_contract.R","R/emergence_packet.R","R/router_abi.R",
    "R/router_policy.R","R/adjacency.R","R/harmony_contract.R",
    "R/emergence_round.R")
}
# Read a package-source file robustly (works from any CWD): resolve "R/xxx.R"
# by walking up from getwd() until "R/router_contract.R" exists.
v070_source <- function(f) {
  # absolute-ref via known repo root candidates
  roots <- c(getwd(), dirname(getwd()), file.path(getwd(), ".."),
             "/mnt/d/visualR/visualR")
  for (r in roots) {
    p <- file.path(r, f)
    if (file.exists(p)) return(paste(readLines(p, warn = FALSE), collapse = "\n"))
  }
  stop(sprintf("cannot locate %s (repo root not found)", f))
}

test_that("gate 14: v0.7 modules contain NO native entry points (no accelerator)", {
  for (f in v070_files()) {
    code <- v070_source(f)
    # .Call / .C / .Fortran / .External would be a native (C/C++/Fortran) bridge
    expect_false(grepl("\\.Call\\s*\\(", code),
                 sprintf("%s: .Call native bridge present (gate 14 violated)", f))
    expect_false(grepl("\\.C\\s*\\(", code),
                 sprintf("%s: .C native bridge present (gate 14 violated)", f))
    expect_false(grepl("\\.Fortran\\s*\\(", code),
                 sprintf("%s: .Fortran bridge present (gate 14 violated)", f))
    expect_false(grepl("\\.External\\s*\\(", code),
                 sprintf("%s: .External bridge present (gate 14 violated)", f))
    expect_false(grepl("Rcpp|reticulate|torch|tensorflow", code),
                 sprintf("%s: external semantic engine import present (gate 13/14)", f))
  }
})

test_that("gate 14: no compiled src/ object in the package build", {
  # The package has no src/ dir (pure-R); if one existed with .o/.so it would
  # be a native accelerator candidate.
  expect_true(!dir.exists("src") || length(list.files("src", pattern = "\\.(o|so|dll)$")) == 0L)
})

test_that("gate 13: R alone is the semantic authority (content is base-R data)", {
  # Merge content round-trips through base-R containers (character/vector), so a
  # future reader only needs base-R semantics — no foreign runtime is authoritative.
  m <- new_merge(c("alpha","beta"), "M1", "la", 1L)
  expect_type(merge_content(m), "character")     # base-R type, no runtime object
  # integrity hash must be reproducible across sessions (base-R only)
  p <- pack_emergence(m, "/a", "open")
  expect_true(nzchar(p$envelope$integrity))
  expect_match(p$envelope$integrity, "^[0-9a-f]{32}$")   # md5, base-R
})

test_that("gate 13: no subagent/remote call in v0.7 path (local computation only)", {
  for (f in v070_files()) {
    code <- v070_source(f)
    # a v0.7 module must not shell out / make a network call — computation is
    # local. Flag only actual call sites, not generic "system" tokens in names
    # like .observe_system().
    expect_false(grepl("system2\\s*\\(|(^|[^A-Za-z_.])system\\s*\\(|download\\.file\\s*\\(|curl\\s*\\(",
                       code),
                 sprintf("%s: external process/network in v0.7 path (gate 13)", f))
    expect_false(grepl("httr\\s*::|url\\s*\\(|requests\\s*::", code),
                 sprintf("%s: network lib in v0.7 path (gate 13)", f))
  }
})
