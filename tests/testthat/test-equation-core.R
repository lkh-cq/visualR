# Test: next-stage equation-core probes.
# These tests validate separations and structural facts, not invented
# values for unknown dimensions.

test_that("dimension_series keeps candidate sequences separate", {
  s <- dimension_series(s_max = 4L, d_max = 5L)
  expect_s3_class(s, "visualr_dimension_series")
  expect_identical(s$status, "candidate_not_frozen")
  expect_identical(s$pal$L_s, c(1L, 3L, 5L, 7L, 9L))
  expect_identical(s$carrier$W_d, c(3L, 4L, 5L, 6L, 7L))
  expect_identical(s$carrier$Q_d, c(4L, 6L, 8L, 10L, 12L))
  expect_identical(s$carrier$area, c(9L, 16L, 25L, 36L, 49L))
  expect_identical(s$carrier$delta_W, c(NA_integer_, 1L, 1L, 1L, 1L))
  expect_identical(s$carrier$delta_Q, c(NA_integer_, 2L, 2L, 2L, 2L))
})

test_that("dimension_series validates index boundaries", {
  expect_error(dimension_series(-1L), "non-negative")
  expect_error(dimension_series(d_max = 0L), "positive")
})

test_that("odd gradient lattice has one geometric center", {
  g <- gradient_lattice(3L)
  m <- gradient_metadata(g)
  expect_s3_class(g, "visualr_gradient_lattice")
  expect_identical(m$center_mode, "odd_single_center")
  expect_identical(m$center_count, 1L)
  expect_identical(m$max_gradient, 2L)
  expect_identical(g$gradient[g$row == 2L & g$col == 2L], 0L)
})

test_that("even gradient lattice exposes a center set, not a single center", {
  g <- gradient_lattice(4L)
  m <- gradient_metadata(g)
  expect_identical(m$center_mode, "even_center_set")
  expect_identical(m$center_count, 4L)
  expect_identical(m$max_gradient, 2L)
  expect_true(all(g$gradient[g$is_center] == 0L))
})

test_that("gradient lattice is coordinate metadata, not symbolic values", {
  g <- gradient_lattice(5L)
  expect_true(all(c("row", "col", "gradient", "is_center",
                    "width", "parity", "center_mode") %in% names(g)))
  expect_false("value" %in% names(g))
})

test_that("gradient_residual is zero for identical fields", {
  x <- matrix(c(0, 1, 2, 1), nrow = 2L)
  r <- gradient_residual(x, x)
  expect_identical(r$max_abs, 0)
  expect_identical(r$mean_abs, 0)
  expect_identical(r$l1, 0)
  expect_identical(r$l2, 0)
  expect_false(r$weighted)
})

test_that("gradient_residual reports explicit error metrics", {
  observed <- matrix(c(0, 1, 2, 3), nrow = 2L)
  predicted <- matrix(c(0, 0, 1, 5), nrow = 2L)
  r <- gradient_residual(observed, predicted)
  expect_identical(r$residual, observed - predicted)
  expect_identical(r$max_abs, 2)
  expect_identical(r$l1, 4)
  expect_identical(r$l2, sqrt(6))
})

test_that("gradient_residual validates dimensions and weights", {
  expect_error(gradient_residual(matrix(1, 2, 2), matrix(1, 3, 1)),
               "identical dimensions")
  x <- matrix(1, 2, 2)
  expect_error(gradient_residual(x, x, matrix(-1, 2, 2)),
               "non-negative")
})

test_that("audit_dimension_sample records parity without interpreting values", {
  odd <- audit_dimension_sample(matrix(letters[1:9], 3L, 3L))
  even <- audit_dimension_sample(matrix(letters[1:16], 4L, 4L))
  expect_identical(odd$parity, "odd")
  expect_identical(even$parity, "even")
  expect_true(odd$values_uninterpreted)
  expect_true(even$values_uninterpreted)
  expect_identical(even$center_mode, "even_center_set")
})

test_that("audit_dimension_sample rejects non-square samples", {
  expect_error(audit_dimension_sample(matrix(1:6, 2L, 3L)),
               "square matrix")
})
