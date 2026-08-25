# v0.8 Registries — MetricLaw & TransportLaw tests (Task 6).
# Covers default registration, hand-computed metric fixtures, fail-closed
# lookup, the grid_identity (flat baseline) transport, and custom metric
# registration + registration-time validation.
# `.onLoad_geometry_defaults()` is run once by helper-geometry.R so the
# built-in manhattan / euclidean / grid_identity entries are present.

.pos_grid <- new_position_state(c("/a", "/b"), c(1, 2), "grid")
.pos_target <- new_position_state(c("/a", "/b"), c(4, 6), "grid")

test_that("default metrics register and compute hand-checked distances", {
  expect_true(has_metric("manhattan"))
  expect_true(has_metric("euclidean"))
  # manhattan: |1-4| + |2-6| = 3 + 4 = 7
  manh <- get_metric("manhattan")
  expect_equal(manh(.pos_grid, .pos_target), 7)
  # euclidean: sqrt((4-1)^2 + (6-2)^2) = sqrt(9 + 16) = 5
  euc <- get_metric("euclidean")
  expect_equal(euc(.pos_grid, .pos_target), 5)
})

test_that("get_metric fails closed on an unknown name", {
  expect_error(get_metric("no_such_metric"), "fail closed")
  expect_false(has_metric("no_such_metric"))
})

test_that("grid_identity transport returns the state unchanged", {
  expect_true(has_transport_law("grid_identity"))
  law <- get_transport_law("grid_identity")
  out <- law(.pos_grid, .pos_grid, .pos_target, regulation = NULL)
  expect_identical(out, .pos_grid)
})

test_that("custom metric registers and can be retrieved", {
  # constant metric: every pair is distance 1
  register_metric("unit", function(a, b) 1)
  expect_true(has_metric("unit"))
  expect_equal(get_metric("unit")(.pos_grid, .pos_target), 1)
})

test_that("registration validation rejects bad names and non-functions", {
  expect_error(register_metric("", function(a, b) 1), "name")
  expect_error(register_metric("bad", 42), "function")
  expect_error(register_transport_law("", function(s, f, t, r) s), "name")
  expect_error(register_transport_law("bad", 42), "function")
})

test_that("register_transport_law stores a retrievable step_fn", {
  register_transport_law("plus_one", function(state, from, to, regulation = NULL) {
    # chain a dummy field to prove the law ran
    state$coordinate <- state$coordinate + 1
    state
  })
  expect_true(has_transport_law("plus_one"))
  out <- get_transport_law("plus_one")(.pos_grid, .pos_grid, .pos_target)
  expect_identical(out$coordinate, .pos_grid$coordinate + 1)
})