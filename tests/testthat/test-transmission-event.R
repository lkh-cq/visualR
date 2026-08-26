# v0.10 Graded Transmission — TransmissionEvent layer tests (Task 3).
# Covers the classify_grade priority chain, event construction invariants
# (T0 no-move / T2 multi-step), grade recomputation (fail closed), and the
# T0 position-invariance predicate.
#
# Movement is addressed by POSITION, not coordinate: classify_grade's addr_eq
# treats two states sharing address+chart+layer as the SAME endpoint (=> T0).
# A genuine elementary move therefore changes the address.
# `.onLoad_geometry_defaults()` is run once by helper-geometry.R.

pos <- function(addr = "/a", coord = 0, cell = "core", layer = 0L, chart = "grid") {
  new_position_state(addr, coord, cell, layer = layer, chart = chart)
}

test_that("classify_grade: layer transition -> T4 even when crossing cell", {
  from <- pos(addr = "/a", layer = 0L)
  to   <- pos(addr = "/b", coord = 2, cell = "periph", layer = 1L)
  expect_identical(classify_grade(from, list(to), boundary_flags = TRUE), "T4")
})

test_that("classify_grade: chart transition -> T4", {
  from <- pos(addr = "/a", chart = "grid")
  to   <- pos(addr = "/b", coord = 1, chart = "polar")
  expect_identical(classify_grade(from, list(to)), "T4")
})

test_that("classify_grade: boundary crossing within same cell -> T3", {
  from <- pos(addr = "/a")
  to   <- pos(addr = "/b", coord = 1)
  expect_identical(classify_grade(from, list(to), boundary_flags = TRUE), "T3")
})

test_that("classify_grade: different cell without boundary flag -> T3", {
  from <- pos(addr = "/a")
  to   <- pos(addr = "/b", coord = 1, cell = "periph")
  expect_identical(classify_grade(from, list(to)), "T3")
})

test_that("classify_grade: two steps in same cell -> T2", {
  from <- pos(addr = "/a")
  to1  <- pos(addr = "/b", coord = 1)
  to2  <- pos(addr = "/c", coord = 2)
  expect_identical(classify_grade(from, list(to1, to2)), "T2")
})

test_that("classify_grade: exactly one elementary edge -> T1", {
  from <- pos(addr = "/a")
  to   <- pos(addr = "/b", coord = 1)
  expect_identical(classify_grade(from, list(to)), "T1")
})

test_that("classify_grade: zero targets -> T0", {
  from <- pos(addr = "/a")
  expect_identical(classify_grade(from, list()), "T0")
})

test_that("classify_grade: target identical to self -> T0", {
  from <- pos(addr = "/a")
  expect_identical(classify_grade(from, list(from)), "T0")
})

test_that("classify_grade: rejects a non-position `from`", {
  expect_error(classify_grade(list(), list(pos())), "visualr_position_state")
})

test_that("new_transmission_event: T0 records zero substeps and no move", {
  from   <- pos(addr = "/a")
  ev     <- new_transmission_event("m0", from, list(from), logical_time = 5L)
  expect_identical(ev$grade, "T0")
  expect_identical(ev$n_substeps, 0L)
  expect_identical(ev$substeps[[1L]]$to, from)
})

test_that("new_transmission_event: T2 keeps two real submoves", {
  from <- pos(addr = "/a")
  to1  <- pos(addr = "/b", coord = 1)
  to2  <- pos(addr = "/c", coord = 2)
  ev   <- new_transmission_event("m1", from, list(to1, to2), logical_time = 1L)
  expect_identical(ev$grade, "T2")
  expect_identical(ev$n_substeps, 2L)
  expect_identical(length(ev$substeps), 2L)
  expect_identical(ev$substeps[[1L]]$to, to1)
  expect_identical(ev$substeps[[2L]]$to, to2)
})

test_that("validate_transmission_event: tampered grade fails closed", {
  from <- pos(addr = "/a")
  to   <- pos(addr = "/b", coord = 1)
  ev   <- new_transmission_event("m1", from, list(to), logical_time = 1L)
  expect_identical(ev$grade, "T1")
  ev$grade <- "T2"   # hand-tamper so it no longer matches geometric facts
  expect_error(validate_transmission_event(ev), "does not match geometric facts")
})

test_that("event_is_position_invariant is TRUE only for T0", {
  from <- pos(addr = "/a")
  t0   <- new_transmission_event("m0", from, list(from), logical_time = 3L)
  t1   <- new_transmission_event("m1", from, list(pos(addr = "/b")),
                                 logical_time = 3L)
  expect_true(event_is_position_invariant(t0))
  expect_false(event_is_position_invariant(t1))
})