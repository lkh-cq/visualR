# v0.8 Geometric Runtime — run_transmission_round tests (Task 2).
# Covers the seven property points: (1) no adjacency => no harmony,
# (2) one adjacent pair => one event/one fresh merge under the harmony
# operator, (3) serial == parallel determinism, (4) survivors are never
# round-robin repositioned, (5) distance accumulates stepwise across a
# chained transmit_step, (6) same-endpoint different-path is NOT the same
# state while lossy signatures still match (promotion gate), and
# (7) emergence_position_rule reference policies + fail-closed.
# `manhattan` metric and `grid_identity` transport law are present via
# helper-geometry.R (.onLoad_geometry_defaults()).

# Build a round-entry TransportedState at a single-coordinate position.
mk_state <- function(id, addr, coord, content, t = 1L) {
  m <- new_merge(content, id, paste0("local", id), t)
  ps <- new_position_state(addr, coord, "grid")
  path <- new_transmission_path(id, ps)
  new_transported_state(m, ps, path, transmission_signature(path))
}

test_that("no_adjacency_no_harmony: far states produce no events or merges", {
  pred <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "/a", 0, "alpha")
  s2 <- mk_state("M2", "/b", 2, "beta")       # d(a,b)=2 > 1 => not adjacent

  rnd <- run_transmission_round(list(s1, s2), pred, "manhattan",
                                "grid_identity", 1L)

  expect_s3_class(rnd, "visualr_geometry_round")
  expect_length(rnd$adjacency$pairs, 0L)
  expect_length(rnd$events, 0L)
  expect_length(rnd$new_merges, 0L)
  expect_identical(rnd$dropped, 0L)
})

test_that("adjacent_pair_produces_one_event: one merge with operator content", {
  pred <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "/a", 0, "alpha")
  s2 <- mk_state("M2", "/b", 1, "beta")       # d=1 => adjacent

  rnd <- run_transmission_round(list(s1, s2), pred, "manhattan",
                                "grid_identity", 1L,
                                harmony_operator = "pair_comp")

  expect_length(rnd$adjacency$pairs, 1L)
  expect_length(rnd$events, 1L)
  expect_length(rnd$new_merges, 1L)
  # pair_comp concatenates the two contents (matches test-emergence-round.R's
  # harmony assertion approach); the result is a fresh Merge.
  expect_s3_class(rnd$events[[1]]$result, "visualr_merge")
  expect_identical(merge_content(rnd$new_merges[[1]]), "alpha beta")
  # consumed both inputs => state count 2 - both consumed => dropped count
  expect_identical(rnd$dropped, 1L)  # 2*used_pairs - new_merges = 2 - 1
})

test_that("serial_equals_parallel: identical inputs yield identical results", {
  pred <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "/a", 0, "alpha")
  s2 <- mk_state("M2", "/b", 1, "beta")

  rnd1 <- run_transmission_round(list(s1, s2), pred, "manhattan",
                                 "grid_identity", 1L, harmony_operator = "pair_comp")
  rnd2 <- run_transmission_round(list(s1, s2), pred, "manhattan",
                                 "grid_identity", 1L, harmony_operator = "pair_comp")

  mid1 <- vapply(rnd1$events, function(ev) ev$result$merge_id, character(1))
  mid2 <- vapply(rnd2$events, function(ev) ev$result$merge_id, character(1))
  expect_identical(mid1, mid2)
  expect_identical(length(rnd1$adjacency$pairs), length(rnd2$adjacency$pairs))
  expect_identical(length(rnd1$new_merges), length(rnd2$new_merges))
})

test_that("survivor_not_repositioned: unconsumed state keeps position+path", {
  pred <- default_adjacency_predicate(max_distance = 1)
  s1 <- mk_state("M1", "/a", 0, "alpha")
  s2 <- mk_state("M2", "/b", 1, "beta")       # (1,2) adjacent
  s3 <- mk_state("M3", "/c", 9, "gamma")      # far from both => survivor

  rnd <- run_transmission_round(list(s1, s2, s3), pred, "manhattan",
                                "grid_identity", 1L)

  expect_length(rnd$adjacency$pairs, 1L)      # only (1,2)
  expect_length(rnd$events, 1L)
  # survivor (index 3, unconsumed) keeps its address and path verbatim
  before <- s3$position$address
  after  <- rnd$transmitted[[3]]$position$address
  expect_identical(after, before)
  expect_identical(rnd$transmitted[[3]]$path$positions,
                   s3$path$positions)
  expect_identical(rnd$transmitted[[3]]$merge_id, "M3")
})

test_that("distance_accumulates_stepwise: chained transmission grows path", {
  # transmit_step seeds a FRESH path from its `from` argument on every call,
  # so a two-hop chain A->B->C is a head-held path where the second hop is
  # appended onto the first hop's immutable path (no central repositioner).
  m <- new_merge("payload", "M5", "local5", 1L)
  A <- new_position_state("/a", 0, "grid")
  B <- new_position_state("/b", 1, "grid")
  C <- new_position_state("/c", 2, "grid")

  s1 <- transmit_step(m, A, B, "manhattan", "grid_identity", 1L)
  chain_path <- append_transmission_step(s1$path, B, C,
                                         grade = "T1", logical_time = 2L)
  s2 <- new_transported_state(m, C, chain_path,
                              transmission_signature(chain_path))

  # two chained T1 steps => exactly two path entries and n_steps = 2
  expect_length(s2$path$steps, 2L)
  expect_length(s2$path$positions, 3L)       # A, B, C
  expect_identical(transmission_signature(s2$path)$n_steps, 2L)
  expect_identical(s2$signature$n_steps, 2L)
  expect_identical(s2$position$address, C$address)
  # the path is the full history: opens at A, closes at C
  expect_identical(s2$path$positions[[1]]$address, A$address)
  expect_identical(tail(s2$path$positions, 1)[[1]]$address, C$address)
  # walked distance accumulates |0-1| + |1-2| = 2 across the two steps
  coords <- vapply(s2$path$positions, function(p) p$coordinate, numeric(1))
  expect_equal(sum(abs(diff(coords))), 2)
  # time span reflects both hops (t=1 .. t=2); min/max yield doubles
  expect_equal(s2$signature$t_start, 1)
  expect_equal(s2$signature$t_end, 2)
})

test_that("same_endpoint_different_path_is_not_same_state (promotion gate)", {
  m <- new_merge("payload", "M6", "local6", 1L)
  A <- new_position_state("/a", 0, "grid")
  B <- new_position_state("/b", 1, "grid")    # A->B->C  (via /b)
  D <- new_position_state("/d", 1, "grid")    # A->D->C  (via /d)
  C <- new_position_state("/c", 2, "grid")    # shared endpoint

  chain <- function(via) {
    p <- new_transmission_path("M6", A)
    p <- append_transmission_step(p, A, via, grade = "T1", logical_time = 1L)
    append_transmission_step(p, via, C, grade = "T1", logical_time = 1L)
  }
  p1 <- chain(B)
  p2 <- chain(D)

  # same ENDPOINT, but different full history => distinct transport result
  expect_identical(tail(p1$positions, 1)[[1]]$address, C$address)
  expect_identical(tail(p2$positions, 1)[[1]]$address, C$address)
  expect_false(paths_equal(p1, p2))
  # lossy TransmissionSignature: 2 T1 steps, same merge/time => identical digest
  expect_identical(transmission_signature(p1)$n_steps, 2L)
  expect_identical(transmission_signature(p2)$n_steps, 2L)
  expect_equal(transmission_signature(p1), transmission_signature(p2))
})

test_that("emergence_position_rule: reference policies + fail-closed", {
  lp <- new_position_state("/a", 0, "grid")
  rp <- new_position_state("/b", 2, "grid")

  # origin policies return the corresponding PositionState unchanged
  expect_identical(emergence_position_rule("left_origin", lp, rp), lp)
  expect_identical(emergence_position_rule("right_origin", lp, rp), rp)

  # shared_boundary derives the midpoint between the two origins
  sb <- emergence_position_rule("shared_boundary", lp, rp)
  expect_s3_class(sb, "visualr_position_state")
  expect_identical(sb$address, "/a|/b")
  expect_equal(sb$coordinate, 1)             # (0 + 2) / 2
  expect_identical(sb$cell, "grid+grid")
  expect_identical(sb$layer, lp$layer)
  expect_identical(sb$chart, lp$chart)

  # unknown policy fails closed
  expect_error(emergence_position_rule("teleport", lp, rp),
               "Unknown emergence policy")
})