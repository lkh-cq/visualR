# Test: benchmark prototype — demo_full_loop + benchmark_all
# The "基准原型 R 包" (2026-08-08): one-command closed-loop baseline.
# Tests assert the loop completes and the measurement suite is
# reproducible, not absolute values.

test_that("demo_full_loop runs the complete closed loop", {
  r <- demo_full_loop()
  expect_type(r, "list")
  expect_true(all(c("pal", "matrix", "verdict", "folded", "pkg",
                    "reload_ok") %in% names(r)))
  expect_s3_class(r$pal, "visualr_pal")
  expect_true(r$verdict %in% c("promote", "transient", "recurse", "reject"))
  expect_s3_class(r$pkg, "visualr_package")
  expect_true(is.logical(r$reload_ok))
})

test_that("demo_full_loop S4 identity round-trips to promote + reload", {
  r <- demo_full_loop(list(shells = c("A", "B", "C", "D"), core = "e"))
  expect_identical(r$verdict, "promote")
  expect_false(is.null(r$folded))
  # Fold-back must reproduce the same canonical PAL string.
  expect_identical(format_pal(r$folded), format_pal(r$pal))
  expect_true(r$reload_ok)
})

test_that("demo_full_loop accepts custom state", {
  r <- demo_full_loop(list(shells = c("A", "B"), core = "c"))
  expect_s3_class(r$pal, "visualr_pal")
  expect_true(r$verdict %in% c("promote", "transient", "recurse", "reject"))
})

test_that("benchmark_all returns all 6 measurement frames", {
  b <- benchmark_all(overhead_reps = 5, latency_reps = 5, throughput_n = 20)
  expect_type(b, "list")
  expect_true(all(c("storage", "transfer", "ram", "overhead",
                    "latency", "throughput") %in% names(b)))
  expect_s3_class(b$storage, "data.frame")
  expect_s3_class(b$transfer, "data.frame")
  expect_s3_class(b$ram, "data.frame")
  expect_s3_class(b$overhead, "data.frame")
  expect_s3_class(b$latency, "data.frame")
  expect_s3_class(b$throughput, "data.frame")
  expect_equal(nrow(b$storage), 5L)   # S1..S5
  expect_equal(nrow(b$throughput), 2L) # serial + concurrent
})

test_that("benchmark_all storage shows S5 PAL advantage", {
  b <- benchmark_all(throughput_n = 10)
  s5 <- b$storage[b$storage$dim == "S5", ]
  expect_true(s5$reduction > 5)
})
