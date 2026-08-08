# Test: COMPLEX recursion family — mixed re-typing over a peel chain.
# The full peel chain (S_n -> ... -> S_0) is retained as recursion
# layers; every level's topology is preserved atomically.

test_that("complex_recurse builds one layer per peeled level", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- complex_recurse(p)
  # S4 chain: S4, S3, S2, S1, S0 = 5 levels.
  expect_s3_class(rc, "visualr_recursion")
  expect_equal(recursion_depth(rc), 5L)
})

test_that("complex_recurse base is the deepest peel (S_0)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- complex_recurse(p)
  # Base layer is S_0 = {A} (peel chain end).
  expect_equal(length(rc$layers[[1]]$shells), 0L)
  expect_identical(rc$layers[[1]]$core, "A")
})

test_that("complex_recurse preserves every level's identity via digest", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  chain <- peel_chain(p)  # S4..S0
  rc <- complex_recurse(p)
  # Base layer (r0) is the deepest peel S_0 = {A}, kept verbatim (not
  # re-typed). Wrapper layers r1..r4 carry the atomic digest of the
  # corresponding chain level: r1 wraps S1, r2 wraps S2, ..., r4 wraps
  # S4.
  expect_identical(rc$layers[[1]]$core, "A")
  expect_equal(length(rc$layers[[1]]$shells), 0L)
  # r1 wraps S1 (chain[[4]]), r2 wraps S2 (chain[[3]]), ...
  for (i in 2:5L) {
    src <- chain[[6L - i]]
    tok <- digest_sha256(format_pal(src))
    expect_identical(rc$layers[[i]]$core, tok,
                     info = paste0("layer r", i - 1L))
  }
})

test_that("complex_recurse is deterministic", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc1 <- complex_recurse(p)
  rc2 <- complex_recurse(p)
  expect_identical(recursion_stack(rc1), recursion_stack(rc2))
})

test_that("complex_recurse rejects invalid pal", {
  expect_error(complex_recurse(42), "visualr_pal")
})
