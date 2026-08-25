# v0.8 Arbitration — shared-resource collision plugin tests.
# Covers the six coverage points: (1) detect_cell_collisions grouping by
# (cell, chart, layer) with >=2 as the only contested cells, (2) fail-closed
# on a non-transported_state, (3) arbitrate_collisions tie-break chain
# (fewer steps wins, then lexicographic merge_id) + winners/losers structure
# disjoint and exhaustive, (4) apply_arbitration deferral (loser rewound to
# previous step with the old path unmutated; n==1 loser stays in place),
# (5) run_transmission_round_arbitrated deconflicts before a single harmony
# event and leaves the far survivor untouched, and (6) determinism across two
# runs of the same arbitrated round. `manhattan` / `grid_identity` are wired
# via helper-geometry.R.

# Build a TransportedState whose current position is (addr, coord, cell) and
# whose path history has exactly `n_steps` T1 steps (n>=1 means the final
# position is reached by stepping; n==0 is a round-entry state).
mk_state <- function(id, cell, coord, addr, n_steps = 1L) {
  m <- new_merge(id, id, paste0("local", id), 1L)
  ps <- vector("list", n_steps + 1L)
  if (n_steps >= 1L) {
    for (k in seq_len(n_steps)) {
      ps[[k]] <- new_position_state(paste0("/", id, "/h", k),
                                    as.numeric(coord - n_steps + k - 1L), "inter")
    }
  }
  ps[[n_steps + 1L]] <- new_position_state(addr, coord, cell)
  p <- new_transmission_path(id, ps[[1L]])
  if (n_steps >= 1L) {
    for (k in seq_len(n_steps)) {
      p <- append_transmission_step(p, ps[[k]], ps[[k + 1L]],
                                    grade = "T1", logical_time = as.integer(k))
    }
  }
  new_transported_state(m, ps[[n_steps + 1L]], p, transmission_signature(p))
}

test_that("detect_cell_collisions: two of three in one cell -> one contested group", {
  s1 <- mk_state("M1", "cellA", 0, "/a", 1L)
  s2 <- mk_state("M2", "cellA", 1, "/b", 1L)
  s3 <- mk_state("M3", "cellB", 5, "/c", 1L)

  coll <- detect_cell_collisions(list(s1, s2, s3))
  expect_length(coll, 1L)                 # only one contested (cell, chart, layer)
  expect_length(coll[[1]], 2L)            # indices 1 and 2 share cellA
  expect_true(setequal(coll[[1]], c(1L, 2L)))
  expect_identical(names(coll), "cellA::grid::0")

  # all-different cells => no contested groups at all
  s4 <- mk_state("M4", "cellD", 0, "/d", 1L)
  coll2 <- detect_cell_collisions(list(s1, s4, s3))
  expect_length(coll2, 0L)
})

test_that("detect_cell_collisions fails closed on a non-transported_state", {
  s1 <- mk_state("M1", "cellA", 0, "/a", 1L)
  s3 <- mk_state("M3", "cellB", 5, "/c", 1L)
  bogus <- list(not = "a transported state")
  expect_error(detect_cell_collisions(list(s1, bogus, s3)),
               "visualr_transported_state")
})

test_that("arbitrate_collisions: lexicographic merge_id breaks an even-step tie", {
  s_a <- mk_state("M1", "cellX", 0, "/a", 1L)
  s_b <- mk_state("M2", "cellX", 1, "/b", 1L)
  coll <- detect_cell_collisions(list(s_a, s_b))
  arb  <- arbitrate_collisions(list(s_a, s_b), coll)

  # equal step count (1==1) => smaller merge_id ("M1" < "M2") wins
  expect_identical(arb$winners[[1]], 1L)
  expect_identical(arb$losers[[1]], 2L)
})

test_that("arbitrate_collisions: fewer accumulated steps wins regardless of id", {
  s_a <- mk_state("MA", "cellY", 0, "/a", 2L)   # 2 steps
  s_b <- mk_state("MB", "cellY", 1, "/b", 3L)   # 3 steps ("MB" < "MA")
  coll <- detect_cell_collisions(list(s_a, s_b))
  arb  <- arbitrate_collisions(list(s_a, s_b), coll)

  # primary key is path length: 2 < 3 => index 1 wins despite larger merge_id
  expect_identical(arb$winners[[1]], 1L)
  expect_identical(arb$losers[[1]], 2L)
})

test_that("arbitrate_collisions: winners/losers are disjoint and exhaustive", {
  s1 <- mk_state("M1", "cellZ", 0, "/a", 1L)
  s2 <- mk_state("M2", "cellZ", 1, "/b", 1L)
  s3 <- mk_state("M3", "cellZ", 2, "/c", 1L)
  coll <- detect_cell_collisions(list(s1, s2, s3))
  arb  <- arbitrate_collisions(list(s1, s2, s3), coll)

  expect_identical(names(arb$winners), names(coll))
  expect_identical(arb$winners[[1]], 1L)
  expect_identical(arb$losers[[1]], c(2L, 3L))
  # no index is both a winner and a loser
  expect_length(intersect(unlist(arb$winners), unlist(arb$losers)), 0L)
  # every index in the contested group is accounted for once (drop the
  # group-key names the named list carries through unlist before comparing)
  accounted <- sort(as.integer(unname(unlist(c(arb$winners, arb$losers)))))
  expect_identical(accounted, 1L:3L)
})

test_that("apply_arbitration: n==1 loser stays in place, source objects unmutated", {
  s1 <- mk_state("M1", "cellR", 0, "/a", 1L)
  s2 <- mk_state("M2", "cellR", 1, "/b", 1L)   # loser, only 1 step => defer in place
  before1 <- s1; before2 <- s2

  coll <- detect_cell_collisions(list(s1, s2))
  arb  <- arbitrate_collisions(list(s1, s2), coll)
  out  <- apply_arbitration(list(s1, s2), arb)

  expect_identical(out$deferred, 2L)
  expect_identical(out$states[[2]]$position, before2$position)
  expect_identical(out$states[[2]]$path, before2$path)
  # winner untouched; neither input object was mutated
  expect_identical(out$states[[1]]$position, before1$position)
  expect_identical(s1, before1)
  expect_identical(s2, before2)
})

test_that("apply_arbitration: loser with >1 step is rewound to previous position", {
  s1 <- mk_state("M1", "cellQ", 0, "/a", 1L)   # winner (fewer steps)
  s2 <- mk_state("M2", "cellQ", 1, "/b", 2L)   # loser, 2 steps -> rewound one step
  coll <- detect_cell_collisions(list(s1, s2))
  arb  <- arbitrate_collisions(list(s1, s2), coll)

  out <- apply_arbitration(list(s1, s2), arb)
  # observable: loser left cellQ and returned to its previous step's position;
  # the rewound path is the n-1=1 step prefix: 2 positions, 1 recorded step
  expect_false(identical(out$states[[2]]$position$cell, "cellQ"))
  expect_length(out$states[[2]]$path$positions, 2L)
  expect_length(out$states[[2]]$path$steps, 1L)
})

test_that("run_transmission_round_arbitrated: one harmony event, far survivor stable", {
  pred  <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "cellA", 0, "/a", 1L)   # same cell, adjacent to s2
  s2 <- mk_state("M2", "cellA", 1, "/b", 1L)   # loses (n==1) -> defer in place
  s3 <- mk_state("M3", "far",   50, "/c", 1L)  # far survivor

  rnd <- run_transmission_round_arbitrated(
    list(s1, s2, s3), pred, "manhattan", "grid_identity", 1L,
    harmony_operator = "pair_comp")

  # deconfliction keeps order; the two adjacent same-cell states meet once
  expect_length(rnd$events, 1L)
  # far survivor was never consumed nor repositioned
  expect_identical(rnd$transmitted[[3]]$position, s3$position)
  # round result is well-formed
  expect_s3_class(rnd, "visualr_geometry_round")
})

test_that("run_transmission_round_arbitrated is deterministic across runs", {
  pred  <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "cellA", 0, "/a", 1L)
  s2 <- mk_state("M2", "cellA", 1, "/b", 1L)

  r1 <- run_transmission_round_arbitrated(list(s1, s2), pred, "manhattan",
                                          "grid_identity", 1L,
                                          harmony_operator = "pair_comp")
  r2 <- run_transmission_round_arbitrated(list(s1, s2), pred, "manhattan",
                                          "grid_identity", 1L,
                                          harmony_operator = "pair_comp")

  mid1 <- vapply(r1$events, function(ev) ev$result$merge_id, character(1))
  mid2 <- vapply(r2$events, function(ev) ev$result$merge_id, character(1))
  expect_identical(mid1, mid2)
  expect_identical(length(r1$adjacency$pairs), length(r2$adjacency$pairs))
})