# Test: SIMPLE recursion family — same-operator re-typing repeated r
# times. Base layer preserved; each re-type wraps the previous top as
# an atomic whole (digest token); un-recurse inverts one layer.

test_that("simple_recurse r=0 returns base-only recursion", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 0L)
  expect_s3_class(rc, "visualr_recursion")
  expect_equal(recursion_depth(rc), 1L)
  expect_identical(rc$layers[[1]], p)
})

test_that("simple_recurse r=n produces depth n+1", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  for (n in 1:4) {
    rc <- simple_recurse(p, n)
    expect_equal(recursion_depth(rc), n + 1L)
  }
})

test_that("simple_recurse base layer is the original pal", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 3L)
  expect_identical(rc$layers[[1]], p)
  expect_identical(format_pal(rc$layers[[1]]), format_pal(p))
})

test_that("re-typed layers are S_0 with atomic digest cores", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 2L)
  # Layers r1, r2 are S_0 wrappers: empty shells.
  expect_equal(length(rc$layers[[2]]$shells), 0L)
  expect_equal(length(rc$layers[[3]]$shells), 0L)
  # Cores are 64-hex digests (no reserved chars, <= MAX_TOKEN_LEN).
  expect_match(rc$layers[[2]]$core, "^[0-9a-f]{64}$")
  expect_match(rc$layers[[3]]$core, "^[0-9a-f]{64}$")
})

test_that("re-type tokens are deterministic and topology-sensitive", {
  p1 <- new_pal_state(c("A", "B", "C", "D"), "e")
  p2 <- new_pal_state(c("A", "B", "C", "D"), "e")
  p3 <- new_pal_state(c("A", "B", "C"), "d")
  rc1 <- simple_recurse(p1, 1L)
  rc2 <- simple_recurse(p2, 1L)
  rc3 <- simple_recurse(p3, 1L)
  expect_identical(rc1$layers[[2]]$core, rc2$layers[[2]]$core)
  expect_false(identical(rc1$layers[[2]]$core, rc3$layers[[2]]$core))
})

test_that("simple_unrecurse inverts one layer", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 3L)  # depth 4
  rc2 <- simple_unrecurse(rc)
  expect_equal(recursion_depth(rc2), 3L)
  expect_identical(format_pal(rc2$layers[[1]]), format_pal(p))
  # Repeated un-recurse down to base (depth 3 -> 2 -> 1).
  rc3 <- simple_unrecurse(simple_unrecurse(rc2))
  expect_equal(recursion_depth(rc3), 1L)
  expect_identical(format_pal(rc3$layers[[1]]), format_pal(p))
})

test_that("simple_unrecurse refuses below base", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 0L)
  expect_error(simple_unrecurse(rc), "below base")
})

test_that("freeze_layer returns canonical PAL of the requested layer", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 2L)
  expect_identical(freeze_layer(rc, 0L), format_pal(p))
  expect_identical(freeze_layer(rc), format_pal(rc$layers[[3]]))
  expect_error(freeze_layer(rc, 99L), "out of range")
})

test_that("recursion_stack returns one canonical PAL per layer", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 2L)
  st <- recursion_stack(rc)
  expect_type(st, "character")
  expect_length(st, 3L)
  expect_identical(st[1], format_pal(p))
})

test_that("simple_recurse rejects negative r", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_error(simple_recurse(p, -1L), "must be >= 0")
})

test_that("new_recursion validates inputs", {
  expect_error(new_recursion(list()), "non-empty")
  expect_error(new_recursion(list(1)), "visualr_pal")
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_s3_class(new_recursion(list(p)), "visualr_recursion")
})
