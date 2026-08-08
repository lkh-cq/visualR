# Test: v0.5.0 Efficiency-gate benchmark suite (7 measurements)
# Covers benchmark_storage (existing) + 6 new measurement functions.
# All tests are structural (schema/positive/ratio direction), not
# absolute-value assertions, so they remain valid across platforms.

test_that("benchmark_transfer returns reproducible schema", {
  b <- benchmark_transfer()
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 5L)
  expect_equal(b$dim, c("S1", "S2", "S3", "S4", "S5"))
  expect_true(all(c("dim", "pal_transfer_bytes", "matrix_transfer_bytes",
                    "transfer_reduction") %in% names(b)))
})

test_that("benchmark_transfer PAL transport bytes grow monotonically", {
  b <- benchmark_transfer()
  expect_true(all(diff(b$pal_transfer_bytes) > 0))
})

test_that("benchmark_transfer S5 shows large PAL advantage", {
  b <- benchmark_transfer()
  s5 <- b[b$dim == "S5", ]
  expect_true(s5$transfer_reduction > 5)
})

test_that("benchmark_transfer S2..S4 show PAL advantage", {
  b <- benchmark_transfer()
  for (nm in c("S2", "S3", "S4")) {
    expect_true(b[b$dim == nm, "transfer_reduction"] > 1, info = nm)
  }
})

test_that("benchmark_peak_ram returns reproducible schema", {
  b <- benchmark_peak_ram()
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 5L)
  expect_true(all(c("dim", "pal_object_bytes", "matrix_object_bytes",
                    "ram_reduction") %in% names(b)))
})

test_that("benchmark_peak_ram S1 matrix view is NA (not a carrier)", {
  b <- benchmark_peak_ram()
  expect_true(is.na(b[b$dim == "S1", "matrix_object_bytes"]))
})

test_that("benchmark_overhead returns non-negative timings", {
  b <- benchmark_overhead(reps = 5)
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 3L)  # S2..S4
  expect_true(all(c("dim", "encode_ms", "expand_ms", "fold_ms") %in% names(b)))
  expect_true(all(b$encode_ms >= 0))
  expect_true(all(b$expand_ms >= 0))
  expect_true(all(b$fold_ms >= 0))
})

test_that("benchmark_latency returns non-negative round-trip time", {
  b <- benchmark_latency(reps = 5)
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 3L)
  expect_true(all(b$roundtrip_ms >= 0))
})

test_that("benchmark_throughput returns serial+concurrent rows", {
  b <- benchmark_throughput(n = 10)
  expect_s3_class(b, "data.frame")
  expect_equal(nrow(b), 2L)
  expect_equal(b$mode, c("serial", "concurrent"))
  expect_true(all(c("mode", "n", "elapsed_ms", "throughput_per_s",
                    "effective_workers") %in% names(b)))
  expect_true(all(b$n == 10L))
  expect_true(all(b$elapsed_ms >= 0))
})
