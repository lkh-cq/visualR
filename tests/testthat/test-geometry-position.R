# v0.8 Geometry Base — PositionState tests (Task 4).
# Covers construction + class name, per-field fail-closed validation,
# the merge attachment seam, and the legacy scalar-address projection.
# `.onLoad_geometry_defaults()` is run once by helper-geometry.R.

test_that("new_position_state constructs a typed PositionState", {
  ps <- new_position_state(c("/a", "/b"), c(1, 2), "core", layer = 1L)
  expect_s3_class(ps, "visualr_position_state")
  expect_identical(ps$address, c("/a", "/b"))
  expect_identical(ps$coordinate, c(1, 2))
  expect_identical(ps$cell, "core")
  expect_identical(ps$layer, 1L)
  expect_identical(ps$chart, "grid")
  expect_true(validate_position_state(ps))
})

test_that("fail-closed: field-level validation rejects bad input", {
  # empty address vector
  expect_error(new_position_state(character(0), numeric(0), "core"),
               "address")
  # address containing empty strings
  expect_error(new_position_state(c("", "/a"), c(1, 2), "core"), "address")
  # coordinate length mismatches address length
  expect_error(new_position_state("/a", c(1, 2), "core"), "coordinate")
  # negative layer
  expect_error(new_position_state("/a", 1, "core", layer = -1L), "layer")
  # non-integer layer
  expect_error(new_position_state("/a", 1, "core", layer = 0.5), "layer")
  # empty cell
  expect_error(new_position_state("/a", 1, ""), "cell")
})

test_that("attach_position_state: matching address attaches cleanly", {
  m <- new_merge("a", "M1", "l", 1L)   # legacy merge has NULL address
  ps <- new_position_state("/a", 1, "core")
  out <- attach_position_state(m, ps)
  expect_s3_class(out, "visualr_merge")
  expect_identical(out$position_state, ps)
  expect_identical(out$address, "/a")
})

test_that("attach_position_state: conflicting address fails closed", {
  m <- new_merge("a", "M1", "l", 1L)
  m$address <- "/a"
  ps <- new_position_state("/b", 1, "core")
  expect_error(attach_position_state(m, ps), "conflicts")
})

test_that("attach_position_state: non-merge object is rejected", {
  expect_error(attach_position_state(list(), new_position_state("/a", 1, "c")),
               "visualr_merge")
})

test_that("merge_position: attached PositionState wins", {
  m <- new_merge("a", "M1", "l", 1L)
  ps <- new_position_state("/a", 1, "core")
  m2 <- attach_position_state(m, ps)   # attach returns a new merge object
  expect_identical(merge_position(m2), ps)
})

test_that("merge_position: projects compatibility from legacy scalar address", {
  m <- new_merge("a", "M1", "l", 1L)
  m$address <- "/a"
  ps <- merge_position(m)
  expect_s3_class(ps, "visualr_position_state")
  expect_identical(ps$address, "/a")
  expect_identical(ps$cell, "legacy")
})

test_that("merge_position: fails closed when no position is present", {
  m <- new_merge("a", "M1", "l", 1L)   # address stays NULL, no position_state
  expect_error(merge_position(m), "no position")
})