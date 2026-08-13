# Test file: shape-preserving block ABI (TCN reference, E)
# TCN TemporalBlock discipline: a block is shape-preserving or it
# declares an explicit adaptation; implicit shape changes are refused.

test_that("identical shapes are shape-preserving", {
  expect_true(check_shape_preserving(c(3L, 3L), c(3L, 3L)))
  expect_true(check_shape_preserving(c(11L, 11L), c(11L, 11L)))
})

test_that("different shapes are not shape-preserving", {
  expect_false(check_shape_preserving(c(3L, 3L), c(4L, 4L)))
  expect_false(check_shape_preserving(c(3L, 3L), c(11L, 11L)))
})

test_that("shape change without adaptation is refused (abi_ok FALSE)", {
  b <- block_contract("jump", c(3L, 3L), c(4L, 4L))
  expect_false(b$abi_ok)
  expect_false(b$shape_preserving)
  expect_null(b$adaptation)
})

test_that("shape change with explicit adaptation is legal", {
  b <- block_contract("jump", c(3L, 3L), c(4L, 4L), "1x1 downsample")
  expect_true(b$abi_ok)
  expect_equal(b$adaptation, "1x1 downsample")
})

test_that("shape-preserving block with adaptation is still legal", {
  b <- block_contract("id", c(3L, 3L), c(3L, 3L))
  expect_true(b$abi_ok)
  expect_true(b$shape_preserving)
})

test_that("invalid inputs fail closed", {
  expect_error(block_contract("", c(3L, 3L), c(3L, 3L)), "non-empty")
  expect_error(block_contract("b", integer(0), c(3L, 3L)), "non-empty")
  expect_error(block_contract("b", c(3L, 3L), c(4L, 4L), 42),
               "adaptation")
})

test_that("print method renders without error", {
  expect_invisible(print(block_contract("id", c(3L, 3L), c(3L, 3L))))
})
