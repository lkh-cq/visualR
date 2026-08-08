# Test: Full-pipeline integration with orbit operators
# PAL -> TopologyCarrier -> Snapshot -> Lanes -> Barrier -> Reconcile
# -> Commit -> PAL re-encoding (closed loop). This is the link that
# proves operators actually run through the whole ABI, not just in
# isolation.

test_that("identity pipeline round-trips PAL unchanged", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, "identity")
  expect_identical(format_pal(res$pal_out), format_pal(p))
  expect_identical(res$carrier_out$cell$singularity, "e")
})

test_that("rotate pipeline re-encodes the rotated PAL", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, "rotate")
  expect_identical(res$pal_out$shells, c("B", "C", "D", "A"))
  expect_identical(res$pal_out$core, "e")
  # and it is a valid pal (round-trips through parse_pal multi-line format)
  expect_identical(parse_pal(format_pal(res$pal_out))$shells,
                   c("B", "C", "D", "A"))
})

test_that("complement pipeline re-encodes the complemented PAL", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, "complement")
  expect_identical(res$pal_out$shells, c("D", "C", "B", "A"))
  expect_identical(res$pal_out$core, "e")
})

test_that("gamma pipeline lowers order and clamps at e", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, "gamma")
  expect_identical(res$pal_out$shells, c("B", "C", "D", "e"))
  expect_identical(res$pal_out$core, "e")
})

test_that("per-lane mixed kernels re-encode correctly", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, list(A = "rotate", B = "gamma",
                                       C = "complement", D = "identity",
                                       e = "identity"))
  # A: rotate -> B; B: gamma -> C; C: complement -> B; D: identity -> D
  expect_identical(res$pal_out$shells, c("B", "C", "B", "D"))
  expect_identical(res$pal_out$core, "e")
})

test_that("pipeline result carries all steps", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p, "rotate")
  expect_true(all(c("carrier_in", "snapshot", "deltas", "barrier",
                    "reconciled", "carrier_out", "pal_out") %in% names(res)))
  expect_true(res$barrier)
  expect_true(res$reconciled$ok)
})

test_that("complement pipeline is a PAL-level involution", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  r1 <- run_topology_pipeline(p, "complement")
  r2 <- run_topology_pipeline(r1$pal_out, "complement")
  expect_identical(format_pal(r2$pal_out), format_pal(p))
})

test_that("cell_to_pal drops missing orbits for shallow states", {
  # S_2: only A, B present -> rotate affects A->B, B->C, others NA
  p <- new_pal_state(c("A", "B"), "c")
  cell <- pal_to_cell(p)
  p2 <- cell_to_pal(cell, p)
  expect_identical(p2$shells, c("A", "B"))
  expect_identical(p2$core, "c")
  # rotate then re-encode: A->B, B->C
  res <- run_topology_pipeline(p, "rotate")
  expect_identical(res$pal_out$shells, c("B", "C"))
  expect_identical(res$pal_out$core, "c")
})

test_that("unknown kernel spec fails closed in pipeline", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_error(run_topology_pipeline(p, "nope"), "Unknown lane kernel")
})
