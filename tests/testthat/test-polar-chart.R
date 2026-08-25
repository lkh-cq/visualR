# Test file: lossless polar observation chart (v0.6.2 experimental)

test_that("polar chart preserves address and value identity", {
  x <- matrix(1:9, nrow = 3L)
  field <- new_numeric_field(x, value_semantics = "fixture",
                             boundary_state = "closed")
  chart <- polar_chart(field)

  expect_s3_class(chart, "visualr_polar_chart")
  expect_identical(chart$data$address_id, field$address$address_id)
  expect_equal(chart$data$value, field$value)
  expect_false(chart$resampled)

  center <- chart$data$row == 2L & chart$data$col == 2L
  top <- chart$data$row == 1L & chart$data$col == 2L
  right <- chart$data$row == 2L & chart$data$col == 3L
  expect_equal(chart$data$r[center], 0)
  expect_true(is.na(chart$data$theta[center]))
  expect_equal(chart$data$theta[top], pi / 2)
  expect_equal(chart$data$theta[right], 0)
})

test_that("even charts distinguish geometric and topology centers", {
  field <- new_numeric_field(matrix(1:16, 4L), value_semantics = "fixture",
                             boundary_state = "closed")
  chart <- polar_chart(field)

  expect_equal(chart$geometric_center, c(row = 2.5, col = 2.5))
  expect_equal(nrow(chart$topology_centers), 4L)
  expect_false(any(chart$data$r == 0))
})

test_that("polar resampling is unavailable until an interpolation contract exists", {
  field <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                             boundary_state = "closed")
  expect_error(polar_chart(field, resample = TRUE), "not implemented")

  path <- new_numeric_field(.numeric_window_fixture(), 1:5, "fixture")
  expect_error(polar_chart(path), "two-dimensional")
})

test_that("derived operations reject a mutated polar chart", {
  field <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                             boundary_state = "closed")
  chart <- polar_chart(field)
  chart$data$value[[1L]] <- 100
  expect_error(field_gradient(field, chart), "chart hash")
})
