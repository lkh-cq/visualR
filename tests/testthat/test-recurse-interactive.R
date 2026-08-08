# Test: INTERACTIVE recursion family — user-driven step up/down via
# the interactive layer. Each step returns a trace (not silent), and
# the recursion object advances/inverts by exactly one layer.

test_that("interactive_step_up advances one layer with trace", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- new_recursion(list(p))
  out <- interactive_step_up(rc)
  expect_type(out, "list")
  expect_true(all(c("rc", "step", "prev_depth", "new_depth",
                    "action") %in% names(out)))
  expect_identical(out$action, "recurse")
  expect_identical(out$step, 1L)
  expect_identical(out$prev_depth, 1L)
  expect_identical(out$new_depth, 2L)
  expect_equal(recursion_depth(out$rc), 2L)
})

test_that("interactive_step_up wraps the top atomically", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- new_recursion(list(p))
  out <- interactive_step_up(rc)
  expect_equal(length(out$rc$layers[[2]]$shells), 0L)
  expect_match(out$rc$layers[[2]]$core, "^[0-9a-f]{64}$")
})

test_that("interactive_step_down inverts one layer with trace", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- simple_recurse(p, 2L)
  out <- interactive_step_down(rc)
  expect_identical(out$action, "unrecurse")
  expect_identical(out$prev_depth, 3L)
  expect_identical(out$new_depth, 2L)
  expect_equal(recursion_depth(out$rc), 2L)
})

test_that("interactive round-trip returns to base", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- new_recursion(list(p))
  up <- interactive_step_up(rc)
  down <- interactive_step_down(up$rc)
  expect_equal(recursion_depth(down$rc), 1L)
  expect_identical(format_pal(down$rc$layers[[1]]), format_pal(p))
})

test_that("interactive_step_down refuses below base", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  rc <- new_recursion(list(p))
  expect_error(interactive_step_down(rc), "below base")
})

test_that("interactive_step_up rejects non-recursion", {
  expect_error(interactive_step_up(42), "visualr_recursion")
  expect_error(interactive_step_down(list()), "visualr_recursion")
})
