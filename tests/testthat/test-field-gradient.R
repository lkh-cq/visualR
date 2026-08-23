# Test file: path and two-dimensional field gradients (v0.6.2 experimental)

test_that("constant two-dimensional field has zero gradient", {
  field <- new_numeric_field(matrix(3, 3L, 3L), value_semantics = "constant",
                             boundary_state = "closed")
  grad <- field_gradient(field, chart = polar_chart(field))

  expect_s3_class(grad, "visualr_field_gradient")
  expect_equal(grad$data$magnitude, rep(0, 9L))
  expect_equal(grad$data$radial[!is.na(grad$data$radial)], 0)
  expect_equal(grad$data$tangential[!is.na(grad$data$tangential)], 0)
})

test_that("affine field gradient matches analytic interior values", {
  coords <- expand.grid(row = 1:3, col = 1:3)
  x <- matrix(2 * coords$row + coords$col, nrow = 3L)
  field <- new_numeric_field(x, value_semantics = "affine",
                             boundary_state = "closed")
  grad <- field_gradient(field)
  center <- grad$data$row == 2L & grad$data$col == 2L

  expect_equal(grad$data$g_col[center], 1)
  expect_equal(grad$data$g_row[center], 2)
  expect_equal(grad$data$magnitude[center], sqrt(5))
})

test_that("path gradient follows global address order", {
  field <- new_numeric_field(.numeric_window_fixture(),
                             c(0, 1, 4, 9, 16), "quadratic")
  grad <- field_gradient(field)

  expect_equal(grad$edges$from_global, 8:11)
  expect_equal(grad$edges$to_global, 9:12)
  expect_equal(grad$edges$coordinate_delta, rep(1, 4L))
  expect_equal(grad$edges$gradient, c(1, 3, 5, 7))
  expect_identical(grad$spacing, c(address = 1))
  expect_identical(grad$mask_policy, "refuse")
})

test_that("non-unit carrier spacing yields physical affine slopes", {
  row_step <- 0.25
  col_step <- 2
  rows <- (0:2) * row_step
  cols <- (0:3) * col_step
  x <- outer(rows, cols, function(r, c) 3 * r - 2 * c + 7)
  field <- new_numeric_field(x, value_semantics = "physical affine",
                             unit = "a.u.", boundary_state = "closed")
  grad <- field_gradient(field, spacing = c(row = row_step, col = col_step))

  expect_equal(grad$data$g_row, rep(3, length(x)), tolerance = 1e-12)
  expect_equal(grad$data$g_col, rep(-2, length(x)), tolerance = 1e-12)
  expect_equal(grad$data$magnitude, rep(sqrt(13), length(x)),
               tolerance = 1e-12)
  expect_identical(grad$spacing, c(row = row_step, col = col_step))
})

test_that("non-unit path spacing is explicit in every edge", {
  field <- new_numeric_field(.numeric_window_fixture(),
                             c(0, 2, 4, 6, 8), "linear physical path")
  grad <- field_gradient(field, spacing = c(address = 0.5))

  expect_equal(grad$edges$address_delta, rep(1L, 4L))
  expect_equal(grad$edges$coordinate_delta, rep(0.5, 4L))
  expect_equal(grad$edges$gradient, rep(4, 4L))
})

test_that("gradient refuses an undefined masked-neighbour policy", {
  field <- new_numeric_field(
    matrix(1:4, 2L), value_semantics = "masked fixture",
    boundary_state = "closed", mask = c(TRUE, TRUE, TRUE, FALSE)
  )
  expect_error(field_gradient(field), "fully observed")
  expect_error(field_gradient(field, masked_policy = "nearest"),
               "Only masked_policy")
})

test_that("gradient spacing rejects ambiguous or unsafe coordinates", {
  carrier <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                               boundary_state = "closed")
  path <- new_numeric_field(.numeric_window_fixture(), 1:5, "fixture")

  expect_error(field_gradient(carrier, spacing = 1), "2 finite positive")
  expect_error(field_gradient(carrier, spacing = c(col = 1, row = 1)),
               "row, col")
  expect_error(field_gradient(carrier, spacing = c(1, 0)), "positive")
  expect_error(field_gradient(path, spacing = c(address = Inf)), "positive")
})

test_that("gradient spacing and mask policy are tamper evident", {
  field <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                             boundary_state = "closed")
  grad <- field_gradient(field, spacing = c(row = 2, col = 3))

  bad_spacing <- grad
  bad_spacing$spacing[["row"]] <- 1
  expect_error(visualR::bias_features(field, gradient = bad_spacing),
               "gradient hash")

  bad_policy <- grad
  bad_policy$mask_policy <- "nearest"
  expect_error(visualR::bias_features(field, gradient = bad_policy),
               "gradient schema")
})
