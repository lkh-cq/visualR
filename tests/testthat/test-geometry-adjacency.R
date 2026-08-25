# v0.8 Adjacency Predicate — default_adjacency_predicate & detect_adjacency
# tests (Task 4). Covers the C_distinct / C_layer / C_space / C_distance
# clauses, max_distance validation, non-PositionState rejection, the pair
# scan (exactly two qualifying pairs with correct indices) plus degenerate
# counts, and mixed transported_state/PositionState input. Defaults (manhattan
# metric) are active via helper-geometry.R.

test_that("predicate rejects identical addresses (C_distinct)", {
  pred <- default_adjacency_predicate()
  p <- new_position_state(c("/a", "/b"), c(0, 0), "grid")
  expect_false(pred(p, p, 1L))
  # a second, identically-addressed state is the same entity
  p2 <- new_position_state(c("/a", "/b"), c(0, 0), "grid")
  expect_false(pred(p, p2, 1L))
})

test_that("predicate rejects cross-layer pairs when same_layer_only=TRUE", {
  pred <- default_adjacency_predicate()   # same_layer_only defaults TRUE
  p1 <- new_position_state("/a", 1, "grid", layer = 0L)
  p2 <- new_position_state("/b", 2, "grid", layer = 1L)
  expect_false(pred(p1, p2, 1L))
  # same layer => allowed to continue to the distance check
  p3 <- new_position_state("/b", 2, "grid", layer = 0L)
  expect_true(pred(p1, p3, 1L))
})

test_that("predicate rejects cross-chart pairs (C_space)", {
  pred <- default_adjacency_predicate()
  p1 <- new_position_state("/a", 0, "grid", chart = "grid")
  p2 <- new_position_state("/b", 1, "grid", chart = "polar")
  expect_false(pred(p1, p2, 1L))
})

test_that("predicate applies C_distance under manhattan (hand-computed)", {
  pred <- default_adjacency_predicate(max_distance = 1)
  # distinct addresses required for C_distinct before distance is compared
  a <- new_position_state("/a", 0, "grid")
  # |0-1| = 1 <= 1 => adjacent
  b1 <- new_position_state("/b", 1, "grid")
  expect_true(pred(a, b1, 1L))
  # |0-2| = 2 > 1 => not adjacent
  b2 <- new_position_state("/c", 2, "grid")
  expect_false(pred(a, b2, 1L))
})

test_that("default_adjacency_predicate validates max_distance (fail closed)", {
  expect_error(default_adjacency_predicate(max_distance = -1), "max_distance")
  expect_error(default_adjacency_predicate(max_distance = NA_real_),
               "max_distance")
})

test_that("predicate fails closed on non-PositionState inputs", {
  pred <- default_adjacency_predicate()
  p <- new_position_state("/a", 0, "grid")
  expect_error(pred(list(), p, 1L), "visualr_position_state")
  expect_error(pred(p, "bogus", 1L), "visualr_position_state")
})

test_that("detect_adjacency finds exactly two qualifying pairs with indices", {
  pred <- default_adjacency_predicate(max_distance = 9)
  s1 <- new_position_state("/a", 0, "grid")
  s2 <- new_position_state("/b", 1, "grid")
  s3 <- new_position_state("/c", 10, "grid")
  # distances: d(1,2)=1, d(1,3)=10, d(2,3)=9  => only (1,2) and (2,3) qualify
  res <- detect_adjacency(list(s1, s2, s3), pred, 1L)

  expect_s3_class(res, "visualr_geometry_adjacency")
  expect_length(res$pairs, 2L)
  expect_identical(res$n_states, 3L)
  expect_identical(res$logical_time, 1L)
  expect_identical(res$pairs[[1]]$left_index, 1L)
  expect_identical(res$pairs[[1]]$right_index, 2L)
  expect_identical(res$pairs[[2]]$left_index, 2L)
  expect_identical(res$pairs[[2]]$right_index, 3L)
})

test_that("detect_adjacency handles single-state and empty lists", {
  pred <- default_adjacency_predicate()
  s <- new_position_state("/a", 0, "grid")
  expect_length(detect_adjacency(list(s), pred, 1L)$pairs, 0L)
  empty <- detect_adjacency(list(), pred, 1L)
  expect_length(empty$pairs, 0L)
  expect_identical(empty$n_states, 0L)
})

test_that("detect_adjacency reads position from mixed transported/plain states", {
  m <- new_merge("a", "M1", "l", 1L)
  ps1 <- new_position_state("/p1", 1, "grid")
  ps2 <- new_position_state("/p2", 2, "grid")
  path <- new_transmission_path("M1", ps1)
  ts <- new_transported_state(m, ps1, path, list(n_steps = 0L),
                              regulation_trace = list())

  res <- detect_adjacency(list(ts, ps2), default_adjacency_predicate(), 1L)
  expect_length(res$pairs, 1L)
  expect_identical(res$pairs[[1]]$left_index, 1L)   # transported_state
  expect_identical(res$pairs[[1]]$right_index, 2L)  # bare PositionState
})