# TCN reference discipline (A-G) — v0.6.0 additive
# Covers: growth_law (D), block_abi (E), carrier_adapter (C+A),
#         emerge_stack (B+F). Status: reference_additive.

test_that("growth_law dilation_power follows 2^i (TCN reference)", {
  expect_identical(growth_law("dilation_power", 0L)$value, 1L)
  expect_identical(growth_law("dilation_power", 3L)$value, 8L)
  expect_identical(growth_sequence("dilation_power", 4L),
                   c(1L, 2L, 4L, 8L, 16L))
})

test_that("growth_law candidate laws stay candidates", {
  # pal_path (L_s = 2s+1) is candidate_not_frozen, value still queryable
  expect_identical(growth_law("pal_path", 4L)$value, 9L)
  expect_false(growth_law("pal_path", 4L)$frozen)
  expect_true(growth_law("dilation_power", 4L)$frozen)
})

test_that("growth_law fails closed on unknown id and bad depth", {
  expect_error(growth_law("nope", 0L), "Unknown law_id")
  expect_error(growth_law("dilation_power", -1L), "non-negative")
  expect_error(growth_sequence("dilation_power", -1L), "non-negative")
})

test_that("check_shape_preserving compares declared shapes only", {
  expect_true(check_shape_preserving(c(3L, 3L), c(3L, 3L)))
  expect_false(check_shape_preserving(c(3L, 3L), c(11L, 11L)))
  expect_false(check_shape_preserving(c(3L, 3L), c(4L, 4L)))
})

test_that("block_contract requires explicit adaptation on shape change", {
  abi_ok_same <- block_contract("b", c(3L, 3L), c(3L, 3L))
  expect_true(abi_ok_same$abi_ok)
  expect_true(abi_ok_same$shape_preserving)

  abi_bad <- block_contract("b", c(3L, 3L), c(4L, 4L))
  expect_false(abi_bad$abi_ok)
  expect_false(abi_bad$shape_preserving)
  expect_null(abi_bad$adaptation)

  abi_ok <- block_contract("b", c(3L, 3L), c(4L, 4L), adaptation = "pad")
  expect_true(abi_ok$abi_ok)
  expect_identical(abi_ok$adaptation, "pad")
})

test_that("carrier_adapter matches pass through, adapts explicitly", {
  m3 <- matrix(1:9, 3L, 3L)
  expect_true(carrier_adapter(m3, 3L, 3L)$matched)
  expect_identical(carrier_adapter(m3, 3L, 3L)$adapted, m3)

  pad <- carrier_adapter(m3, 3L, 4L)
  expect_identical(dim(pad$adapted), c(4L, 4L))
  expect_identical(pad$rule, "border_pad_3to4")

  m4 <- matrix(1:16, 4L, 4L)
  crop <- carrier_adapter(m4, 4L, 3L)
  expect_identical(dim(crop$adapted), c(3L, 3L))
  expect_identical(crop$rule, "border_crop_4to3")
})

test_that("carrier_adapter refuses illegal transfers (typed view)", {
  m3 <- matrix(1:9, 3L, 3L)
  # 3x3 -> 11x11: S_5 carrier view must be built by carrier_11x11()
  expect_error(carrier_adapter(m3, 3L, 11L), "typed view discipline")
  # illegal width fails closed
  expect_error(carrier_adapter(matrix(1:25, 5L, 5L), 5L, 5L),
               "Legal widths")
  # width mismatch between x and from_width
  expect_error(carrier_adapter(m3, 4L, 4L), "from_width")
})

test_that("emerge_stack derives dilation and ABI from width list", {
  s3 <- emerge_stack(c(3L, 3L, 3L))
  expect_true(s3$abi_ok)
  expect_identical(s3$levels$dilation, c(1L, 2L, 4L))

  s4 <- emerge_stack(c(3L, 4L, 4L))
  expect_true(s4$abi_ok)
  expect_false(s4$levels$shape_preserving[2])  # level 2 adapts
  expect_match(s4$levels$adaptation[2], "carrier_adapter 3x3 -> 4x4")

  expect_error(emerge_stack(integer(0)), "positive widths")
  expect_error(emerge_stack(c(3L, 0L)), "positive widths")
})
