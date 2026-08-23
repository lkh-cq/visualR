# Test file: unitary spectral observation plan (v0.6.2 experimental)

test_that("unitary spectrum round-trips and preserves Parseval energy", {
  x <- matrix(c(0, 1, 0, 1, 2, 1, 0, 1, 0), 3L)
  field <- new_numeric_field(x, value_semantics = "fixture",
                             boundary_state = "closed")
  plan <- compile_spectral_plan(
    field, domain = "carrier", boundary_policy = "finite_window"
  )
  spectrum <- execute_spectral_plan(field, plan)
  reconstructed <- inverse_spectral(spectrum)

  expect_s3_class(plan, "visualr_spectral_plan")
  expect_s3_class(spectrum, "visualr_spectrum")
  expect_s3_class(reconstructed, "visualr_numeric_field")
  expect_equal(Re(reconstructed$value), field$value, tolerance = 1e-12)
  expect_equal(sum(Mod(spectrum$coefficient)^2),
               sum(Mod(field$value)^2), tolerance = 1e-12)
})

test_that("spectral boundary policy is explicit and never inferred", {
  closed <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                              boundary_state = "closed")
  open <- new_numeric_field(.numeric_window_fixture(), 1:5, "fixture")

  expect_error(compile_spectral_plan(closed, domain = "carrier"),
               "boundary_policy")
  expect_error(
    compile_spectral_plan(open, "path", "periodic"),
    "open field"
  )

  plan <- compile_spectral_plan(open, "path", "finite_window")
  expect_equal(plan$completeness, "window_only")
})

test_that("spectral plans fail after field identity changes", {
  a <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                         boundary_state = "closed")
  b <- new_numeric_field(matrix(c(1:8, 10), 3L), value_semantics = "fixture",
                         boundary_state = "closed")
  plan <- compile_spectral_plan(a, "carrier", "finite_window")
  expect_error(execute_spectral_plan(b, plan), "source hash")

  plan$boundary_state <- "open"
  expect_error(execute_spectral_plan(a, plan), "plan contract|plan hash")
})

test_that("direct angular modes require declared sampling weights", {
  x <- matrix(c(0, -1, 0, 0, 0, 0, 0, 1, 0), 3L)
  field <- new_numeric_field(x, value_semantics = "x_coordinate",
                             boundary_state = "closed")
  chart <- polar_chart(field)
  weights <- ifelse(is.na(chart$data$theta), 0, 1)

  modes <- angular_modes(field, chart, modes = -1:1, weights = weights)
  expect_s3_class(modes, "visualr_angular_modes")
  expect_equal(modes$normalization, "declared_weighted_mean")
  expect_error(angular_modes(field, chart, 0:1), "weights")
})

test_that("spectral execution refuses an undefined masked-sample policy", {
  field <- new_numeric_field(
    matrix(1:9, 3L), value_semantics = "masked fixture",
    boundary_state = "closed", mask = c(rep(TRUE, 8L), FALSE)
  )
  expect_error(
    compile_spectral_plan(field, "carrier", "finite_window"),
    "fully observed"
  )
})

test_that("spectral observations reject coefficient-energy drift", {
  field <- new_numeric_field(matrix(1:4, 2L), value_semantics = "fixture",
                             boundary_state = "closed")
  plan <- compile_spectral_plan(field, "carrier", "finite_window")
  spectrum <- execute_spectral_plan(field, plan)
  spectrum$coefficient[[1L]] <- spectrum$coefficient[[1L]] + 1
  expect_error(inverse_spectral(spectrum), "energy contract")
})
