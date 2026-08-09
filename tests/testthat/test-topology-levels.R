# Test: Branch-1 — additional topology levels (S_5+, S_3, S_2, S_1)
# Validation uses STRUCTURAL INVARIANTS (round-trip, involution,
# period), not prior-value assertions: this algorithm has no precedent
# to copy expectations from (user 2026-08-09). S_4-only evidence hid
# the S_5 shell truncation; these tests cover every level.

# every level: identity round-trips PAL -> carrier -> PAL unchanged
test_that("round-trip invariant holds at every topology level", {
  states <- list(
    S5 = new_pal_state(c("A", "B", "C", "D", "E"), "f"),
    S4 = new_pal_state(c("A", "B", "C", "D"), "e"),
    S3 = new_pal_state(c("A", "B", "C"), "d"),
    S2 = new_pal_state(c("A", "B"), "c"),
    S1 = new_pal_state(c("A"), "b")
  )
  for (nm in names(states)) {
    p <- states[[nm]]
    res <- run_topology_pipeline(p, "identity")
    expect_identical(format_pal(res$pal_out), format_pal(p),
                     info = paste0("round-trip ", nm))
  }
})

# every level: complement is an involution C^2 = I at the PAL level
test_that("complement involution holds at every topology level", {
  states <- list(
    S5 = new_pal_state(c("A", "B", "C", "D", "E"), "f"),
    S4 = new_pal_state(c("A", "B", "C", "D"), "e"),
    S3 = new_pal_state(c("A", "B", "C"), "d"),
    S2 = new_pal_state(c("A", "B"), "c"),
    S1 = new_pal_state(c("A"), "b")
  )
  for (nm in names(states)) {
    p <- states[[nm]]
    r1 <- run_topology_pipeline(p, "complement")
    r2 <- run_topology_pipeline(r1$pal_out, "complement")
    expect_identical(format_pal(r2$pal_out), format_pal(p),
                     info = paste0("C^2=I ", nm))
  }
})

# rotate must eventually return to the origin (period is a MEASURED
# fact, not a prior value). Current: cycle table covers A..D only, so
# the period is 4 at every level (E+ frozen). Recorded, not frozen.
test_that("rotate has a finite period at every level (measured)", {
  states <- list(
    S5 = new_pal_state(c("A", "B", "C", "D", "E"), "f"),
    S4 = new_pal_state(c("A", "B", "C", "D"), "e"),
    S3 = new_pal_state(c("A", "B", "C"), "d")
  )
  for (nm in names(states)) {
    p <- states[[nm]]
    cur <- p
    period <- NA_integer_
    for (i in 1:12) {
      cur <- run_topology_pipeline(cur, "rotate")$pal_out
      if (identical(format_pal(cur), format_pal(p))) { period <- i; break }
    }
    expect_false(is.na(period), info = paste0("rotate period ", nm))
    expect_true(period >= 1L && period <= 12L,
                info = paste0("rotate period in range ", nm))
  }
})

# S_5 keeps all 5 shells through the pipeline (the Branch-1 fix:
# S_4-only evidence hid the truncation)
test_that("S_5 keeps all shells through rotate pipeline", {
  p5 <- new_pal_state(c("A", "B", "C", "D", "E"), "f")
  res <- run_topology_pipeline(p5, "rotate")
  expect_length(res$pal_out$shells, 5L)
  expect_identical(res$pal_out$core, "f")
})

# shallow states (S_2/S_1) keep their shells through pipelines
test_that("shallow states keep shells through rotate", {
  p2 <- new_pal_state(c("A", "B"), "c")
  r2 <- run_topology_pipeline(p2, "rotate")
  expect_identical(r2$pal_out$shells, c("B", "C"))
  expect_identical(r2$pal_out$core, "c")
  p1 <- new_pal_state(c("A"), "b")
  r1 <- run_topology_pipeline(p1, "rotate")
  expect_identical(r1$pal_out$shells, "B")
  expect_identical(r1$pal_out$core, "b")
})

# concurrent lanes are semantically equal to serial at S_5 too
test_that("S_5 concurrent == serial (performance-only difference)", {
  skip_on_cran()
  p5 <- new_pal_state(c("A", "B", "C", "D", "E"), "f")
  r_s <- run_topology_pipeline(p5, "rotate")
  r_p <- run_topology_pipeline_parallel(p5, "rotate", "psock", ncores = 2L)
  expect_identical(format_pal(r_p$pal_out), format_pal(r_s$pal_out))
})
