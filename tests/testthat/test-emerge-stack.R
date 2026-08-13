# Test file: derived emergence stack (TCN reference, B + F)
# TCN num_channels discipline: width list defines the stack; each
# level derives dilation (growth-law table) and ABI records.

test_that("shape-preserving stack is abi_ok", {
  s <- emerge_stack(c(3L, 3L, 3L))
  expect_true(s$abi_ok)
  expect_equal(s$n_levels, 3L)
  expect_true(all(s$levels$shape_preserving))
})

test_that("width-changing stack declares explicit adaptations", {
  s <- emerge_stack(c(3L, 4L, 4L))
  expect_true(s$abi_ok)
  expect_true(s$levels$shape_preserving[1])   # level 1: 3->3
  expect_false(s$levels$shape_preserving[2])  # level 2: 3->4 adapted
  expect_true(s$levels$shape_preserving[3])   # level 3: 4->4
  expect_match(s$levels$adaptation[2], "carrier_adapter")
})

test_that("dilation follows growth_law dilation_power = 2^(k-1)", {
  s <- emerge_stack(c(3L, 3L, 3L, 3L))
  expect_equal(s$levels$dilation, c(1L, 2L, 4L, 8L))
})

test_that("level widths match the input list", {
  s <- emerge_stack(c(3L, 4L, 4L, 11L))
  expect_equal(s$levels$width, c(3L, 4L, 4L, 11L))
})

test_that("invalid widths fail closed", {
  expect_error(emerge_stack(integer(0)), "non-empty")
  expect_error(emerge_stack(c(3L, NA_integer_)), "positive")
  expect_error(emerge_stack(c(3L, 0L)), "positive")
  expect_error(emerge_stack(c(3L, "x")), "integer")
})

test_that("print method renders without error", {
  expect_invisible(print(emerge_stack(c(3L, 3L))))
})
