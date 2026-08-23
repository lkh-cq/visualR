# Test file: structural bias evidence and reference threshold (v0.6.2)

test_that("bias features are evidence, not a probability", {
  field <- new_numeric_field(.numeric_window_fixture(), 1:5, "fixture",
                             mask = c(TRUE, TRUE, FALSE, TRUE, TRUE))
  features <- bias_features(field)

  expect_true(is.numeric(features))
  expect_equal(features[["B_boundary"]], 1)
  expect_equal(features[["B_coverage"]], 0.2)
  expect_false(any(grepl("prob", names(features), ignore.case = TRUE)))
})

test_that("polar and spectral evidence remain explicit components", {
  field <- new_numeric_field(matrix(1, 3L, 3L), value_semantics = "fixture",
                             boundary_state = "closed")
  chart <- polar_chart(field)
  plan <- compile_spectral_plan(field, "carrier", "finite_window")
  spectrum <- execute_spectral_plan(field, plan)
  gradient <- field_gradient(field, chart)
  features <- bias_features(field, chart, spectrum, gradient)

  expect_equal(features[["B_polar"]], 0)
  expect_equal(features[["B_spectral"]], 1)
  expect_equal(features[["B_gradient"]], 0)
})

test_that("reference threshold uses robust component-wise normalization", {
  reference <- data.frame(
    B_boundary = c(0, 0, 0, 1, 0, 0),
    B_coverage = c(0, 0.01, 0.02, 0.01, 0.03, 0.02)
  )
  threshold <- fit_reference_threshold(reference, alpha = 0.1)
  ordinary <- audit_bias(c(B_boundary = 0, B_coverage = 0.02), threshold)
  extreme <- audit_bias(c(B_boundary = 1, B_coverage = 0.8), threshold)

  expect_s3_class(threshold, "visualr_bias_threshold")
  expect_s3_class(ordinary, "visualr_bias_audit")
  expect_equal(ordinary$action, "within_reference")
  expect_equal(extreme$action, "review")
  expect_true(extreme$aggregate > threshold$threshold)
})

test_that("bias audit fails closed on feature drift", {
  threshold <- fit_reference_threshold(
    data.frame(a = c(0, 1, 2), b = c(2, 1, 0)), alpha = 0.1
  )
  expect_error(audit_bias(c(a = 1), threshold), "feature names")
  expect_error(fit_reference_threshold(data.frame(a = 1:2), 0.1),
               "at least three")

  threshold$scale[[1L]] <- 0
  expect_error(audit_bias(c(a = 1, b = 1), threshold),
               "threshold contract")
})

test_that("gradient evidence is source-bound and tamper-evident", {
  field <- new_numeric_field(matrix(1:9, 3L), value_semantics = "fixture",
                             boundary_state = "closed")
  gradient <- field_gradient(field)
  expect_true(bias_features(field, gradient = gradient)[["B_gradient"]] > 0)
  gradient$data$magnitude[[1L]] <- gradient$data$magnitude[[1L]] + 1
  expect_error(bias_features(field, gradient = gradient), "gradient hash")
})
