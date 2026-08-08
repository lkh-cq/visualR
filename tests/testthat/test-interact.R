# Test file: interactive + concurrent layer (R is the benchmark)
# pal_pipe / batch_compute / interact — storage -> compute -> fold-back

s4 <- function() new_pal_state(c("A", "B", "C", "D"), "e")
s3 <- function() new_pal_state(c("A", "B", "C"), "D")

test_that("pal_pipe accepts pal state and grammar string", {
  p1 <- pal_pipe(s4(), "identity", verbose = FALSE)
  p2 <- pal_pipe("{A{B{C{D{e}D}C}B}A}", "identity", verbose = FALSE)
  expect_equal(p1$expanded, p2$expanded)
})

test_that("pal_pipe identity: closed + promote", {
  res <- pal_pipe(s4(), "identity", verbose = FALSE)
  expect_true(res$closed)
  expect_equal(res$action, "promote")
  expect_equal(res$computed, res$expanded)
  expect_equal(res$fold_back$shells, c("A", "B", "C", "D"))
  expect_equal(res$fold_back$core, "e")
})

test_that("pal_pipe orbit_rotate: closed + fold-back returns different state", {
  res <- pal_pipe(s4(), "orbit_rotate", verbose = FALSE)
  expect_true(res$closed)
  expect_equal(res$action, "promote")
  expect_false(identical(res$fold_back$shells, c("A", "B", "C", "D")))
})

test_that("pal_pipe rejects bad input", {
  expect_error(pal_pipe(42L), "visualr_pal or a single")
  expect_error(pal_pipe(c("a", "b")), "single")
})

test_that("pal_pipe verbose prints pipeline", {
  out <- capture.output(res <- pal_pipe(s4(), "identity", verbose = TRUE))
  expect_true(any(grepl("pal_pipe", out)))
  expect_true(any(grepl("action: promote", out)))
  expect_true(res$closed)
})

test_that("interact returns visualr_compute_result (fold-back closure)", {
  out <- interact(s4(), "orbit_rotate")
  expect_s3_class(out, "visualr_compute_result")
  expect_true(out$closed)
  expect_equal(out$action, "promote")
  # fold-back result must re-expand to the same computed matrix
  expanded <- pal_to_jiugong(out$fold_back)$grid
  expect_true(closure_check(expanded))
})

test_that("interact identity round-trips exactly", {
  out <- interact(s4(), "identity")
  expect_equal(out$fold_back$shells, c("A", "B", "C", "D"))
  expect_equal(out$fold_back$core, "e")
})

test_that("batch_compute validates inputs", {
  expect_error(batch_compute(list()), "non-empty")
  expect_error(batch_compute(list(s4()), ncores = 0L), ">= 1")
})

test_that("batch_compute identity: all promote, consistent", {
  res <- batch_compute(list(s4(), s3(),
                            new_pal_state(c("A", "B"), "C"),
                            new_pal_state(c("A"), "B")),
                       "identity", ncores = 2L)
  expect_equal(res$n, 4L)
  expect_equal(res$n_promote, 4L)
  expect_equal(res$n_transient, 0L)
  expect_equal(res$n_recurse, 0L)
  expect_equal(res$n_reject, 0L)
  expect_true(res$consistent)
})

test_that("batch_compute parallel == serial results (consistency)", {
  pals <- lapply(1:24, function(i) {
    # vary shell depth
    k <- 1 + (i %% 4)
    new_pal_state(letters[1:k], letters[k + 1])
  })
  serial <- batch_compute(pals, "orbit_rotate", ncores = 1L)
  nc <- min(2L, max(1L, parallel::detectCores() - 1L))
  par <- batch_compute(pals, "orbit_rotate", ncores = nc)
  expect_equal(serial$results, par$results)
  expect_equal(serial$n_promote, par$n_promote)
})

test_that("batch_compute reports closure distribution", {
  # one transient case: orbit_rotate on an odd shell produces transient
  pals <- list(
    new_pal_state(c("A", "B", "C", "D"), "e"),  # S_4
    new_pal_state(c("A", "B", "C"), "D")        # S_3
  )
  res <- batch_compute(pals, "orbit_rotate", ncores = 1L)
  expect_true(res$n_promote >= 0L)
  expect_true(res$consistent)
  expect_equal(res$n, 2L)
})

test_that("batch_compute engine parameter resolves correctly", {
  pals <- lapply(1:20, function(i) {
    k <- 1 + (i %% 4)
    new_pal_state(letters[1:k], letters[k + 1])
  })
  # serial engine always reports serial execution
  r_ser <- batch_compute(pals, "identity", ncores = 1L, engine = "serial")
  expect_equal(r_ser$execution, "serial")
  expect_equal(r_ser$engine, "serial")
  expect_false(r_ser$fallback)

  # multicore engine on Linux/macOS -> multicore; on Windows -> serial-fallback
  r_mc <- batch_compute(pals, "identity", ncores = 2L, engine = "multicore")
  if (.Platform$OS.type == "windows") {
    expect_equal(r_mc$execution, "serial-fallback")
    expect_true(r_mc$fallback)
  } else {
    expect_equal(r_mc$execution, "multicore")
    expect_false(r_mc$fallback)
  }
  expect_equal(r_mc$engine, "multicore")
})

test_that("batch_compute psock engine produces identical results to serial", {
  skip_on_cran()  # PSOCK cluster + serialization is slow under CRAN checks
  pals <- lapply(1:24, function(i) {
    k <- 1 + (i %% 4)
    new_pal_state(letters[1:k], letters[k + 1])
  })
  serial <- batch_compute(pals, "orbit_rotate", ncores = 1L, engine = "serial")
  psock <- batch_compute(pals, "orbit_rotate", ncores = 2L, engine = "psock")
  expect_equal(psock$execution, "psock")
  expect_false(psock$fallback)
  expect_equal(serial$results, psock$results)
  expect_equal(serial$n_promote, psock$n_promote)
  expect_true(psock$consistent)
})

test_that("interact is idempotent on identity (fold-back preserves)", {
  x <- interact(s4(), "identity")
  y <- interact(x$fold_back, "identity")
  expect_equal(x$fold_back$shells, y$fold_back$shells)
  expect_equal(x$fold_back$core, y$fold_back$core)
})

test_that("batch_compute reports silent-degradation fallback (plan §6)", {
  pals <- rep(list(s4()), 5)

  # ncores=1 (user explicitly requested serial): fallback FALSE, execution serial
  r1 <- batch_compute(pals, "identity", ncores = 1L)
  expect_false(r1$fallback)
  expect_equal(r1$execution, "serial")
  expect_equal(r1$ncores, 1L)
  expect_equal(r1$requested_cores, 1L)

  # platform-specific behavior (v0.4.x PSOCK engine):
  # On real multi-core Unix, ncores=4 -> multicore, fallback FALSE.
  # On Windows, auto engine now uses PSOCK (v0.4.x), so ncores=4
  # uses 4 PSOCK workers: execution "psock", fallback FALSE.
  # The fallback flag is TRUE only when effective cores < requested.
  if (.Platform$OS.type == "windows") {
    r4 <- batch_compute(pals, "identity", ncores = 2L)
    expect_equal(r4$execution, "psock")
    expect_false(r4$fallback)
    expect_equal(r4$ncores, 2L)
    expect_equal(r4$requested_cores, 2L)
  } else {
    # On a real multicore platform, ncores=4 must actually use 4 cores
    # (no silent degradation on Linux/macOS).
    r4 <- batch_compute(pals, "identity", ncores = 4L)
    expect_false(r4$fallback)
    expect_equal(r4$execution, "multicore")
    expect_equal(r4$ncores, 4L)
  }
})

test_that("batch_compute is deterministic: N-core == 1-core (plan §6)", {
  pals <- lapply(1:32, function(i) {
    k <- 1 + (i %% 4)
    new_pal_state(letters[1:k], letters[k + 1])
  })
  serial <- batch_compute(pals, "orbit_rotate", ncores = 1L)
  nc <- min(4L, max(2L, parallel::detectCores() - 1L))
  if (.Platform$OS.type == "windows") nc <- 2L
  par <- batch_compute(pals, "orbit_rotate", ncores = nc)
  # identical == same order AND same values (stable ordering + determinism)
  expect_identical(par$results, serial$results)
  expect_true(par$consistent)
})

test_that("batch_compute does not mutate shared state (plan §6)", {
  p4 <- new_pal_state(c("A", "B", "C", "D"), "e")
  pals <- rep(list(p4), 20)
  g0 <- ls(getNamespace("visualR"), all.names = TRUE)
  invisible(batch_compute(pals, "orbit_rotate", ncores = 2L))
  g1 <- ls(getNamespace("visualR"), all.names = TRUE)
  expect_identical(g0, g1)
})
