# Test: benchmark_storage() — v0.4.x measurement harness
# Verifies the reproducible stored-bytes measurement function.

test_that("benchmark_storage returns reproducible data.frame", {
  b <- benchmark_storage()
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 5L)  # S1..S5
  expect_true(all(c("dim", "pal_bytes", "matrix_bytes", "cells", "reduction") %in% names(b)))
  expect_equal(b$dim, c("S1", "S2", "S3", "S4", "S5"))
})

test_that("benchmark_storage PAL bytes are positive and monotone in dim", {
  b <- benchmark_storage()
  expect_true(all(b$pal_bytes > 0))
  # PAL serialization grows with shell count (S1..S5 strictly increasing)
  expect_true(all(diff(b$pal_bytes) > 0))
})

test_that("benchmark_storage high-dim S5 shows PAL advantage (reduction > 1)", {
  b <- benchmark_storage()
  s5 <- b[b$dim == "S5", ]
  # S5 uses the 11x11 carrier (121 cells); PAL O(n) beats matrix O(n^2)
  expect_equal(s5$cells, 121L)
  expect_true(s5$reduction > 1)
  # the 11x11 advantage should be large (PAL much smaller than matrix)
  expect_gt(s5$reduction, 5)
})

test_that("benchmark_storage 3x3 states show PAL advantage (reduction > 1)", {
  b <- benchmark_storage()
  for (nm in c("S2", "S3", "S4")) {
    r <- b[b$dim == nm, "reduction"]
    expect_true(r > 1, info = nm)
  }
})

test_that("benchmark_storage S1 is not a 3x3 carrier (matrix_bytes NA)", {
  b <- benchmark_storage()
  s1 <- b[b$dim == "S1", ]
  expect_true(is.na(s1$matrix_bytes))
  expect_true(is.na(s1$reduction))
})