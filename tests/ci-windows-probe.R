# Windows post-install smoke diagnostic: 5 independent probes
# Each probe exits immediately after its check, so the first failure
# pinpoints the exact boundary that breaks.
#
# W1  Rscript/sessionInfo     -> R engine alive?
# W2  library(visualR)        -> package loads in fresh session?
# W3  new_pal_state           -> constructor works?
# W4  materialize             -> mapping pack dispatch works?
# W5  assertion              -> return contract (m$ok) correct?

cat("=== W1: Rscript/sessionInfo ===\n")
cat("R version:", R.version.string, "\n")
cat("OS:", .Platform$OS.type, "\n")
cat("Platform:", .Platform$platform, "\n")
cat("W1: PASS\n\n")

cat("=== W2: library(visualR) ===\n")
library(visualR)
cat("visualR version:", as.character(packageVersion("visualR")), "\n")
cat("visualR path:", find.package("visualR"), "\n")
cat("W2: PASS\n\n")

cat("=== W3: new_pal_state ===\n")
p <- new_pal_state(c("A", "B", "C", "D"), "e")
cat("class:", class(p), "\n")
cat("shells:", paste(p$shells, collapse=""), "\n")
cat("core:", p$core, "\n")
cat("W3: PASS\n\n")

cat("=== W4: materialize ===\n")
m <- materialize(p, "canonical_jiugong")
cat("ok:", m$ok, "\n")
cat("carrier:", m$carrier, "\n")
cat("grid rows:", nrow(m$grid), "\n")
cat("grid cols:", ncol(m$grid), "\n")
cat("grid:\n")
print(m$grid)
cat("W4: PASS\n\n")

cat("=== W5: assertion ===\n")
stopifnot(m$ok == TRUE)
cat("m$ok is TRUE:", m$ok, "\n")
cat("W5: PASS\n\n")

cat("=== ALL 5 PROBES PASSED ===\n")
