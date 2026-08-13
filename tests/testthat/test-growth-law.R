# Test file: growth-law frozen constant table (TCN reference, D)
# Reference: IMPLEMENTATION_PLAN_v0.6.0.md + TCN dilation=2^i discipline.
# candidate laws (carrier_width, pal_path) are NOT frozen -- the table
# exposes them side by side with the frozen reference laws.

test_that("dilation_power follows base^depth (TCN reference)", {
  expect_equal(growth_law("dilation_power", 0L)$value, 1L)
  expect_equal(growth_law("dilation_power", 3L)$value, 8L)
  expect_equal(growth_law("dilation_power", 5L)$value, 32L)
})

test_that("growth_sequence produces the explicit TCN sequence", {
  expect_equal(growth_sequence("dilation_power", 4L),
               c(1L, 2L, 4L, 8L, 16L))
})

test_that("candidate laws stay candidate_not_frozen", {
  p <- growth_law("pal_path", 4L)
  expect_equal(p$value, 9L)         # 2*4+1
  expect_false(p$frozen)            # NOT frozen
  w <- growth_law("carrier_width", 5L)
  expect_equal(w$value, 7L)         # 5+2
  expect_false(w$frozen)
})

test_that("frozen reference law is marked frozen", {
  d <- growth_law("dilation_power", 2L)
  expect_true(d$frozen)
  expect_equal(d$value, 4L)
})

test_that("unknown law_id fails closed", {
  expect_error(growth_law("nope", 0L), "Unknown law_id")
})

test_that("invalid depth fails closed", {
  expect_error(growth_law("dilation_power", -1L), "non-negative")
  expect_error(growth_law("dilation_power", "x"), "integer")
})

test_that("print method renders without error", {
  expect_invisible(print(growth_law("dilation_power", 1L)))
})
