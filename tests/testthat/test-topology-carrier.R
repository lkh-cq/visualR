# Test: Topology Operator ABI v0.1 — full pipeline
# TopologyCarrier -> Snapshot -> Concurrent Lanes -> Reconcile -> Commit
# The most fragile link is PAL -> TopologyCell restoration: orbits/
# phase/origin must be restored in ONE step, never char-by-char.

test_that("pal_to_cell restores four orbits + singularity (fragile link)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cell <- pal_to_cell(p)
  expect_s3_class(cell, "visualr_topology_cell")
  expect_identical(cell$singularity, "e")
  expect_identical(names(cell$orbits), c("A", "B", "C", "D"))
  expect_identical(cell$orbits$A, c("A", "A"))
  expect_identical(cell$orbits$B, c("B", "B"))
  expect_identical(cell$orbits$C, c("C", "C"))
  expect_identical(cell$orbits$D, c("D", "D"))
})

test_that("pal_to_cell restores containment order (outermost = A)", {
  p <- new_pal_state(c("X", "Y", "Z", "W"), "q")
  cell <- pal_to_cell(p)
  expect_identical(cell$singularity, "q")
  expect_identical(cell$orbits$A, c("X", "X"))
  expect_identical(cell$orbits$B, c("Y", "Y"))
  expect_identical(cell$orbits$C, c("Z", "Z"))
  expect_identical(cell$orbits$D, c("W", "W"))
})

test_that("pal_to_cell handles shallow states (missing orbits -> NA)", {
  p <- new_pal_state(c("A", "B"), "c")
  cell <- pal_to_cell(p)
  expect_identical(cell$singularity, "c")
  expect_identical(cell$orbits$A, c("A", "A"))
  expect_identical(cell$orbits$B, c("B", "B"))
  expect_true(all(is.na(cell$orbits$C)))
  expect_true(all(is.na(cell$orbits$D)))
})

test_that("pal_to_cell handles S_0 (no shells)", {
  p <- new_pal_state(character(0), "A")
  cell <- pal_to_cell(p)
  expect_identical(cell$singularity, "A")
  expect_true(all(is.na(cell$orbits$A)))
})

test_that("new_topology_cell validates orbits", {
  expect_error(new_topology_cell("e", list(A = "A", B = "B")),
               "named list|missing")
  expect_error(new_topology_cell("e", list(A = c("A", "A"), B = c("B", "B"),
                                           C = c("C", "C"), D = "D")),
               "2-char endpoint")
  expect_error(new_topology_cell(NA_character_, list(A = c("A","A"),
    B = c("B","B"), C = c("C","C"), D = c("D","D"))),
    "single non-NA")
})

test_that("new_topology_carrier holds axes + projection", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  expect_s3_class(cr, "visualr_carrier")
  expect_identical(cr$axes, c("space", "operator", "phase", "channel"))
  expect_identical(dim(cr$projection), c(3L, 3L))
  expect_identical(cr$projection[2, 2], "e")
  expect_identical(cr$projection[1, 1], "A")
})

test_that("snapshot freezes carrier state", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  snap <- snapshot(cr)
  expect_s3_class(snap, "visualr_snapshot")
  expect_true(snap$frozen)
  expect_identical(snap$cell$singularity, "e")
})

test_that("execute_lanes dispatches 5 concurrent lanes", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  snap <- snapshot(cr)
  deltas <- execute_lanes(snap)
  expect_identical(names(deltas), c("A", "B", "C", "D", "e"))
  expect_identical(deltas$A$result, c("A", "A"))
  expect_identical(deltas$e$result, "e")
})

test_that("barrier accepts complete deltas and rejects incomplete", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  deltas <- execute_lanes(snapshot(cr))
  expect_true(barrier(deltas))
  expect_error(barrier(deltas[1:3]), "missing lane")
})

test_that("reconcile identity lanes promote with no conflicts", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  deltas <- execute_lanes(snapshot(cr))
  rec <- reconcile(deltas, cr$cell)
  expect_true(rec$ok)
  expect_identical(rec$action, "promote")
  expect_length(rec$conflicts, 0L)
  expect_identical(rec$reconciled_cell$singularity, "e")
})

test_that("reconcile detects malformed lane results (fail-closed)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  deltas <- execute_lanes(snapshot(cr))
  deltas$B <- list(bad = TRUE)  # malformed
  rec <- reconcile(deltas, cr$cell)
  expect_false(rec$ok)
  expect_identical(rec$action, "reject")
  expect_true(length(rec$conflicts) > 0L)
})

test_that("commit produces S_(t+1) carrier", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  deltas <- execute_lanes(snapshot(cr))
  rec <- reconcile(deltas, cr$cell)
  out <- commit(rec, cr)
  expect_s3_class(out, "visualr_carrier")
  expect_identical(out$cell$singularity, "e")
  expect_identical(out$pal$core, "e")
})

test_that("commit fails closed on rejected state", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  cr <- new_topology_carrier(p)
  expect_error(commit(list(ok = FALSE, action = "reject"), cr),
               "fail-closed")
  expect_error(commit(list(ok = FALSE), cr), "fail-closed")
})

test_that("run_topology_pipeline completes the full loop", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p)
  expect_true(all(c("carrier_in", "snapshot", "deltas", "barrier",
                    "reconciled", "carrier_out") %in% names(res)))
  expect_true(res$barrier)
  expect_true(res$reconciled$ok)
  expect_s3_class(res$carrier_out, "visualr_carrier")
  # S_(t+1) retains the same singularity (identity pipeline)
  expect_identical(res$carrier_out$cell$singularity, "e")
})

test_that("pipeline restores full topology (no flattening)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  res <- run_topology_pipeline(p)
  cell <- res$carrier_out$cell
  # Orbits carry endpoint PAIRS, not 9 independent cells
  expect_identical(length(cell$orbits$A), 2L)
  expect_identical(length(cell$orbits$B), 2L)
  expect_identical(length(cell$orbits$C), 2L)
  expect_identical(length(cell$orbits$D), 2L)
  # 3x3 projection is a VIEW, not the object
  expect_true(!is.null(res$carrier_in$projection))
})
