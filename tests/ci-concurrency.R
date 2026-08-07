# CI post-check script: concurrency invariant + smoke test
# Runs on ALL platforms (Linux, Windows, macOS)
library(visualR)

pals <- lapply(1:24, function(i) {
  k <- 1 + (i %% 4)
  new_pal_state(letters[1:k], letters[k + 1])
})

s <- batch_compute(pals, "orbit_rotate", ncores = 1)
cat("OK: 1-core baseline (", length(s$results), "states)\n")

n <- parallel::detectCores()
if (is.na(n)) n <- 2
nc <- max(2, min(n, 4))

if (.Platform$OS.type == "windows") {
  # Windows: mclapply falls back to serial in batch_compute, so nc>1 is safe
  # but detectCores() may report more than available; cap at 2
  nc <- min(nc, 2)
}

p <- batch_compute(pals, "orbit_rotate", ncores = nc)
stopifnot(identical(s$results, p$results))
cat("OK: 1-core ==", nc, "-core\n")
cat("ALL CHECKS PASSED\n")
