# Test the v0.6.2 evidence harness schema and fail-closed boundaries.

test_that("numeric observer benchmark is deterministic in schema", {
  result <- benchmark_numeric_observers(sizes = c(1L, 3L), reps = 1L,
                                        batches = 1L)

  expect_s3_class(result, "data.frame")
  expect_identical(
    names(result),
    c("operation", "side", "cells", "reps", "batches", "median_ms",
      "result_bytes", "semantic_authority", "status")
  )
  expect_setequal(
    unique(result$operation),
    c("numeric_field", "polar_chart", "spectral_execute",
      "spectral_inverse", "field_gradient", "bias_features",
      "signal_schedule")
  )
  expect_true(all(result$median_ms >= 0))
  expect_true(all(result$result_bytes > 0))
  expect_true(all(result$semantic_authority == "R"))
})

test_that("tap compiler benchmark checks native equivalence", {
  result <- benchmark_tap_compiler(widths = c(5L, 9L), levels = 2L,
                                   reps = 1L, batches = 1L)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("r", "c") %in% result$engine))
  expect_true(all(result$equivalent_to_r))
  expect_true(all(result$semantic_authority == "R"))
  expect_true(all(result$taps > 0L))
  expect_true(all(result$median_ms >= 0))
})

test_that("v0.6.2 benchmarks reject unsafe workloads", {
  expect_error(benchmark_numeric_observers(sizes = c(3L, 3L)), "unique")
  expect_error(benchmark_numeric_observers(sizes = 0L), "sizes")
  expect_error(benchmark_tap_compiler(widths = 4L), "odd")
  expect_error(benchmark_tap_compiler(widths = 5L, reps = 0L), "reps")
})
