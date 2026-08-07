# Test: concurrency_report() — v0.4.x concurrent-throughput harness

test_that("concurrency_report returns data.frame with expected columns", {
  r <- concurrency_report(sizes = c(50L, 200L), ncores_vec = c(1L, 2L), trials = 1)
  expect_s3_class(r, "data.frame")
  expect_true(all(c("size", "ncores", "serial_s", "parallel_s", "speedup", "fallback") %in% names(r)))
  # 2 sizes x 2 cores = 4 rows
  expect_equal(nrow(r), 4L)
})

test_that("concurrency_report single-core speedup is exactly 1", {
  r <- concurrency_report(sizes = 100L, ncores_vec = 1L, trials = 1)
  expect_equal(r$speedup, 1.0)
  expect_equal(r$parallel_s, r$serial_s)
  expect_false(r$fallback)
})

test_that("concurrency_report validates inputs", {
  expect_error(concurrency_report(sizes = 0L), "positive")
  expect_error(concurrency_report(ncores_vec = 0L), "positive")
  expect_error(concurrency_report(trials = 0L), ">= 1")
})

test_that("concurrency_report reports fallback when requested cores not used", {
  # On Windows, ncores=4 forces serial fallback (fallback TRUE)
  # On Linux/macOS, ncores=4 uses multicore (fallback FALSE)
  r <- concurrency_report(sizes = 50L, ncores_vec = 4L, trials = 1)
  if (.Platform$OS.type == "windows") {
    expect_true(r$fallback)
  } else {
    expect_false(r$fallback)
  }
})

test_that("concurrency_health reports platform-correct fork support", {
  h <- concurrency_health()
  expect_true(all(c("platform", "fork_supported", "detect_cores",
                    "recommended_cores", "effective_mode") %in% names(h)))
  # fork unavailable only on Windows
  expect_equal(h$fork_supported, .Platform$OS.type != "windows")
  # recommended >= 1 always
  expect_gte(h$recommended_cores, 1L)
  # effective mode consistent with fork_supported
  if (h$fork_supported && h$recommended_cores > 1L) {
    expect_equal(h$effective_mode, "multicore")
  } else {
    expect_equal(h$effective_mode, "serial")
  }
})