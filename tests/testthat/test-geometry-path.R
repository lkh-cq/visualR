# v0.8 Path Base — TransmissionPath tests (Task 5).
# Covers immutable append-only history, fail-closed head matching,
# grade / logical_time validation, path equality (same endpoint but
# different history => unequal), and the lossy TransmissionSignature.

# Fixture: a start position plus three distinct positions.
.pos0 <- new_position_state("/p0", 0, "grid")
.pos1 <- new_position_state("/p1", 1, "grid")
.pos2 <- new_position_state("/p2", 2, "grid")
.pos3 <- new_position_state("/p3", 3, "grid")

.build_three_step_path <- function(grades = c("T1", "T1", "T1")) {
  path <- new_transmission_path("m1", .pos0)
  path <- append_transmission_step(path, .pos0, .pos1, grades[1], 0L)
  path <- append_transmission_step(path, .pos1, .pos2, grades[2], 1L)
  append_transmission_step(path, .pos2, .pos3, grades[3], 2L)
}

test_that("append accumulates positions and steps immutably", {
  path <- new_transmission_path("m1", .pos0)
  expect_s3_class(path, "visualr_transmission_path")
  expect_equal(path_length_steps(path), 0L)
  expect_length(path$positions, 1L)

  grown <- append_transmission_step(path, .pos0, .pos1, "T1", 0L)
  # original untouched — build-on-copy
  expect_equal(path_length_steps(path), 0L)
  expect_equal(path_length_steps(grown), 1L)
  expect_length(grown$positions, 2L)
  expect_identical(grown$positions[[2]], .pos1)

  full <- .build_three_step_path()
  expect_equal(path_length_steps(full), 3L)
  expect_length(full$positions, 4L)
  expect_length(full$steps, 3L)
  expect_identical(full$positions[[4]], .pos3)
})

test_that("fail closed: step `from` must match current path head", {
  path <- new_transmission_path("m1", .pos0)
  expect_error(append_transmission_step(path, .pos1, .pos2, "T1", 1L),
               "current path head")
})

test_that("fail closed: only T1-T4 grades are accepted", {
  path <- new_transmission_path("m1", .pos0)
  expect_error(append_transmission_step(path, .pos0, .pos1, "T5", 0L), "grade")
  expect_error(append_transmission_step(path, .pos0, .pos1, "T0", 0L), "grade")
  expect_error(append_transmission_step(path, .pos0, .pos1, 1, 0L), "grade")
})

test_that("fail closed: logical_time must be a non-negative integer", {
  path <- new_transmission_path("m1", .pos0)
  expect_error(append_transmission_step(path, .pos0, .pos1, "T1", -1L),
               "logical_time")
  expect_error(append_transmission_step(path, .pos0, .pos1, "T1", 0.5),
               "logical_time")
  expect_error(append_transmission_step(path, .pos0, .pos1, "T1", "1"),
               "logical_time")
})

test_that("paths_equal: same endpoint but different history => FALSE", {
  # identical endpoints / positions, differing step grades
  p1 <- .build_three_step_path(grades = c("T1", "T1", "T1"))
  p2 <- .build_three_step_path(grades = c("T2", "T2", "T2"))
  expect_identical(p1$positions, p2$positions)   # same endpoint reached
  expect_false(paths_equal(p1, p2))
  # a path equals itself
  expect_true(paths_equal(p1, p1))
})

test_that("transmission_signature: lossy audit digest is correct", {
  path <- .build_three_step_path(grades = c("T1", "T2", "T1"))
  sig <- transmission_signature(path)
  expect_identical(sig$merge_id, "m1")
  expect_identical(sig$n_steps, 3L)
  expect_equal(sig$t_start, 0)   # vapply(..., numeric()) -> double min
  expect_equal(sig$t_end, 2)
  expect_identical(as.integer(sig$grade_counts["T1"]), 2L)
  expect_identical(as.integer(sig$grade_counts["T2"]), 1L)
})

test_that("two different paths can share one signature (holonomy warning)", {
  # Three-step T1/T2/T1 vs a shuffled but same-count path; distinct histories,
  # identical lossy digest — signature equality must NOT imply equality.
  pA <- .build_three_step_path(grades = c("T1", "T2", "T1"))
  pB <- .build_three_step_path(grades = c("T2", "T1", "T1"))
  expect_false(paths_equal(pA, pB))
  sA <- transmission_signature(pA)
  sB <- transmission_signature(pB)
  expect_identical(sA$n_steps, sB$n_steps)
  expect_identical(unname(sA$grade_counts), unname(sB$grade_counts))
  expect_identical(sA$t_start, sB$t_start)
  expect_identical(sA$t_end, sB$t_end)
})