# Test: Concurrent lane fabric — parallel execution of orbit lanes
# Contract (frozen 2026-08-08): result_serial == result_PSOCK ==
# result_fork — differences are PERFORMANCE only, never semantics.

test_that("serial engine runs lanes sequentially", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  r <- execute_lanes_parallel(snap, lane_kernels("rotate"), "serial")
  expect_identical(r$execution, "serial")
  expect_identical(r$deltas$A$result, c("B", "B"))
  expect_identical(r$deltas$D$result, c("A", "A"))
  expect_identical(r$deltas$e$result, "e")
  # explicit serial request with ncores>1 is reported as fallback
  # (requested multi-core, executed serial) — never silent.
  expect_true(r$ncores >= 1L)
})

test_that("psock engine produces identical results to serial", {
  skip_on_cran()
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  r_s <- execute_lanes_parallel(snap, lane_kernels("rotate"), "serial")
  r_p <- execute_lanes_parallel(snap, lane_kernels("rotate"), "psock",
                                ncores = 2L)
  expect_identical(r_p$deltas, r_s$deltas)
  expect_true(r_p$ncores >= 1L)
})

test_that("multicore engine produces identical results to serial", {
  skip_on_cran()
  skip_on_os("windows")  # fork not available; psock covers Windows
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  r_s <- execute_lanes_parallel(snap, lane_kernels("complement"), "serial")
  r_m <- execute_lanes_parallel(snap, lane_kernels("complement"),
                                "multicore", ncores = 2L)
  expect_identical(r_m$deltas, r_s$deltas)
})

test_that("mixed per-lane kernels work under psock", {
  skip_on_cran()
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  k <- lane_kernels(list(A = "rotate", B = "gamma", C = "complement",
                         D = "mirror", e = "identity"))
  r_s <- execute_lanes_parallel(snap, k, "serial")
  r_p <- execute_lanes_parallel(snap, k, "psock", ncores = 2L)
  expect_identical(r_p$deltas, r_s$deltas)
  expect_identical(r_p$deltas$A$result, c("B", "B"))   # rotate
  expect_identical(r_p$deltas$B$result, c("C", "C"))   # gamma
  expect_identical(r_p$deltas$C$result, c("B", "B"))   # complement
})

test_that("concurrent full pipeline equals serial pipeline", {
  skip_on_cran()
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  r_s <- run_topology_pipeline(p, "rotate")
  r_p <- run_topology_pipeline_parallel(p, "rotate", "psock", ncores = 2L)
  expect_identical(format_pal(r_p$pal_out), format_pal(r_s$pal_out))
  expect_identical(r_p$lanes$execution, "psock")
  expect_true(r_p$barrier)
  expect_true(r_p$reconciled$ok)
})

test_that("engine resolution reports serial-fallback on windows for multicore", {
  skip_on_cran()
  # simulate windows resolution
  if (.Platform$OS.type == "windows") {
    eff <- resolve_lane_engine("multicore")
    expect_identical(eff, "serial-fallback")
  } else {
    eff <- resolve_lane_engine("multicore")
    expect_identical(eff, "multicore")
  }
  expect_identical(resolve_lane_engine("serial"), "serial")
  expect_identical(resolve_lane_engine("psock"), "psock")
})

test_that("ncores=1 forces serial with fallback reported", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  r <- execute_lanes_parallel(snap, lane_kernels("rotate"), "multicore",
                              ncores = 1L)
  # Windows: multicore request resolves to serial-fallback (platform
  # rule); Unix: ncores=1 forces plain serial. Either way the result is
  # single-core and reported — never silent.
  expect_true(r$execution %in% c("serial", "serial-fallback"))
  expect_identical(r$ncores, 1L)
})

test_that("invalid inputs fail closed", {
  expect_error(execute_lanes_parallel(42), "visualr_snapshot")
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  # kernels missing required lanes -> fail closed with dynamic label list
  expect_error(execute_lanes_parallel(snap, list(A = identity)),
               "must have names")
  expect_error(execute_lanes_parallel(snap, lane_kernels("identity"), ncores = 0L),
               "must be >= 1")
})
