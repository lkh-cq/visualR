# Test: NESTED recursion family — recursion inside recursion.
# Re-typing applies to the recursion object itself; depth query works
# at every nesting level; inner topology is preserved atomically.

test_that("nested_recurse r=0 returns the same recursion", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 1L)
  rc2 <- nested_recurse(rc, 0L)
  expect_equal(recursion_depth(rc2), recursion_depth(rc))
  expect_identical(recursion_stack(rc2), recursion_stack(rc))
})

test_that("nested_recurse extends the stack by r layers", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 1L)  # depth 2
  rc2 <- nested_recurse(rc, 2L)
  expect_equal(recursion_depth(rc2), 4L)
})

test_that("nested_recurse preserves all prior layers", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 2L)  # r0..r2
  before <- recursion_stack(rc)
  rc2 <- nested_recurse(rc, 1L)
  after_prefix <- recursion_stack(rc2)[1:3]
  expect_identical(after_prefix, before)
})

test_that("nested wrapper cores are atomic digests", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 1L)
  rc2 <- nested_recurse(rc, 2L)
  for (i in 3:4) {
    expect_match(rc2$layers[[i]]$core, "^[0-9a-f]{64}$",
                 info = paste0("layer r", i - 1L))
  }
})

test_that("nested_recurse depth is queryable via recursion_depth", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- nested_recurse(new_recursion(list(p)), 3L)
  expect_equal(recursion_depth(rc), 4L)
  expect_equal(length(recursion_stack(rc)), 4L)
})

test_that("nested_recurse rejects negative r", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_error(nested_recurse(new_recursion(list(p)), -1L), "must be >= 0")
})

test_that("nested_recurse rejects non-recursion input", {
  expect_error(nested_recurse(42), "visualr_recursion")
})

test_that("recursion_stack order is base-first for nested too", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- nested_recurse(new_recursion(list(p)), 2L)
  st <- recursion_stack(rc)
  expect_identical(st[1], format_pal(p))
  expect_length(st, 3L)
})
