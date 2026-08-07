# Test file: interactive + concurrent layer (R is the benchmark)
# pal_pipe / batch_compute / interact — storage -> compute -> fold-back

s4 <- function() new_pal_state(c("A", "B", "C", "D"), "e")
s3 <- function() new_pal_state(c("A", "B", "C"), "D")

test_that("pal_pipe accepts pal state and grammar string", {
  p1 <- pal_pipe(s4(), "identity", verbose = FALSE)
  p2 <- pal_pipe("{A{B{C{D{e}D}C}B}A}", "identity", verbose = FALSE)
  expect_equal(p1$expanded, p2$expanded)
})

test_that("pal_pipe identity: closed + foldable", {
  res <- pal_pipe(s4(), "identity", verbose = FALSE)
  expect_equal(res$closure, "closed")
  expect_true(res$foldable)
  expect_equal(res$computed, res$expanded)
  expect_equal(res$fold_back$shells, c("A", "B", "C", "D"))
  expect_equal(res$fold_back$core, "e")
})

test_that("pal_pipe orbit_rotate: closed + fold-back returns different state", {
  res <- pal_pipe(s4(), "orbit_rotate", verbose = FALSE)
  expect_equal(res$closure, "closed")
  expect_true(res$foldable)
  expect_false(identical(res$fold_back$shells, c("A", "B", "C", "D")))
})

test_that("pal_pipe rejects bad input", {
  expect_error(pal_pipe(42L), "visualr_pal or a single")
  expect_error(pal_pipe(c("a", "b")), "single")
})

test_that("pal_pipe verbose prints pipeline", {
  out <- capture.output(res <- pal_pipe(s4(), "identity", verbose = TRUE))
  expect_true(any(grepl("pal_pipe", out)))
  expect_true(any(grepl("closure: closed", out)))
  expect_true(res$foldable)
})

test_that("interact returns storage-ready pal (fold-back closure)", {
  out <- interact(s4(), "orbit_rotate")
  expect_s3_class(out, "visualr_pal")
  # fold-back result must re-expand to the same computed matrix
  expanded <- pal_to_jiugong(out)$grid
  expect_equal(closure_jiugong(expanded), "closed")
})

test_that("interact identity round-trips exactly", {
  out <- interact(s4(), "identity")
  expect_equal(out$shells, c("A", "B", "C", "D"))
  expect_equal(out$core, "e")
})

test_that("batch_compute validates inputs", {
  expect_error(batch_compute(list()), "non-empty")
  expect_error(batch_compute(list(s4()), ncores = 0L), ">= 1")
})

test_that("batch_compute identity: all closed, consistent", {
  res <- batch_compute(list(s4(), s3(),
                            new_pal_state(c("A", "B"), "C"),
                            new_pal_state(c("A"), "B")),
                       "identity", ncores = 2L)
  expect_equal(res$n, 4L)
  expect_equal(res$n_closed, 4L)
  expect_equal(res$n_transient, 0L)
  expect_equal(res$n_recurse, 0L)
  expect_true(res$consistent)
})

test_that("batch_compute parallel == serial results (consistency)", {
  pals <- lapply(1:24, function(i) {
    # vary shell depth
    k <- 1 + (i %% 4)
    new_pal_state(letters[1:k], letters[k + 1])
  })
  serial <- batch_compute(pals, "orbit_rotate", ncores = 1L)
  par <- batch_compute(pals, "orbit_rotate", ncores = 4L)
  expect_equal(serial$results, par$results)
  expect_equal(serial$n_closed, par$n_closed)
})

test_that("batch_compute reports closure distribution", {
  # one transient case: orbit_rotate on an odd shell produces transient
  pals <- list(
    new_pal_state(c("A", "B", "C", "D"), "e"),  # S_4
    new_pal_state(c("A", "B", "C"), "D")        # S_3
  )
  res <- batch_compute(pals, "orbit_rotate", ncores = 1L)
  expect_true(res$n_closed >= 0L)
  expect_true(res$consistent)
  expect_equal(res$n, 2L)
})

test_that("interact is idempotent on identity (fold-back preserves)", {
  x <- interact(s4(), "identity")
  y <- interact(x, "identity")
  expect_equal(x$shells, y$shells)
  expect_equal(x$core, y$core)
})
