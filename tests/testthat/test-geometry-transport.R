# v0.8 Transport — transmit_step & TransportedState tests (Task 3).
# Covers the normal path, metric / transport-law fail-closed lookup, a
# fail-closed on a law that returns no $position, a custom non-identity
# law proving the payload is never mutated, and a negative-distance metric
# that must abort the step. `.onLoad_geometry_defaults()` runs via
# helper-geometry.R, so manhattan + grid_identity are present.

test_that("transmit_step builds a TransportedState on the normal path", {
  m <- new_merge("payload_a", "M1", "local1", 1L)
  from <- new_position_state(c("/a", "/b"), c(0, 0), "grid")
  to   <- new_position_state(c("/a", "/b"), c(1, 0), "grid")

  st <- transmit_step(m, from, to, "manhattan", "grid_identity", 1L)

  expect_s3_class(st, "visualr_transported_state")
  # identity preserved — transport does NOT create a fresh Merge
  expect_identical(st$merge_id, "M1")
  expect_identical(st$merge$merge_id, "M1")
  # transported position is the destination (identity law keeps it)
  expect_identical(st$position, to)
  # path: start + one step
  expect_length(st$path$steps, 1L)
  expect_length(st$path$positions, 2L)
  expect_identical(st$path$positions[[2]], to)
  # lossy signature reflects the single T1 step
  expect_identical(st$signature$merge_id, "M1")
  expect_identical(st$signature$n_steps, 1L)
  # regulation_trace carries the hand-computed distance: |0-1|+|0-0| = 1
  expect_equal(st$regulation_trace$distance, 1)
  expect_identical(st$regulation_trace$regulation, NULL)
})

test_that("transmit_step fails closed on unknown metric or transport law", {
  m  <- new_merge("a", "M2", "l", 1L)
  from <- new_position_state("/p", 0, "grid")
  to   <- new_position_state("/q", 1, "grid")
  expect_error(transmit_step(m, from, to, "no_such_metric",
                             "grid_identity", 1L), "metric")
  expect_error(transmit_step(m, from, to, "manhattan",
                             "no_such_law", 1L), "transport law")
})

test_that("transmit_step fails closed when the law returns no $position", {
  register_transport_law("no_position_law", function(state, from, to, regulation) {
    list(dropped = TRUE)   # not a wrapped position
  })
  m  <- new_merge("a", "M3", "l", 1L)
  from <- new_position_state("/p", 0, "grid")
  to   <- new_position_state("/q", 1, "grid")
  expect_error(transmit_step(m, from, to, "manhattan",
                             "no_position_law", 1L), "\\$position")
})

test_that("a custom non-identity law moves state but never mutates payload", {
  # shift the transported position's coordinate by +1 from the destination;
  # the merge (payload) is passed by identity and must remain untouched.
  register_transport_law("shift_one", function(state, from, to, regulation = NULL) {
    p <- state$position
    p$coordinate <- p$coordinate + 1
    list(position = p)
  })
  m  <- new_merge("opaque_payload", "M4", "local4", 7L)
  from <- new_position_state(c("/a", "/b"), c(2, 3), "grid")
  to   <- new_position_state(c("/a", "/b"), c(5, 3), "grid")

  st <- transmit_step(m, from, to, "manhattan", "shift_one", 2L)

  # coordinate changed relative to destination => law ran
  expect_identical(st$position$coordinate, c(6, 4))
  # payload identity preserved: same merge_id and same logical_time object
  expect_identical(st$merge_id, "M4")
  expect_identical(st$merge$merge_id, "M4")
  expect_identical(st$merge$logical_time, 7L)
  # signature still reflects one T1 step to the original destination
  expect_identical(st$signature$n_steps, 1L)
})

test_that("a negative-distance metric aborts the step (fail closed)", {
  register_metric("neg_dist", function(a, b) -1)
  m  <- new_merge("a", "M5", "l", 1L)
  from <- new_position_state("/p", 0, "grid")
  to   <- new_position_state("/q", 1, "grid")
  expect_error(transmit_step(m, from, to, "neg_dist",
                             "grid_identity", 1L), "non-negative")
})