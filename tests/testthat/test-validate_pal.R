# Test file: validate_pal
# TDD RED phase — tests written before implementation

test_that("validate_pal accepts valid S_4 (V1)", {
  pal <- pal_fixture_n4()
  expect_invisible(validate_pal(pal))
})

test_that("validate_pal accepts valid S_0 (V2)", {
  pal <- pal_fixture_n0()
  expect_invisible(validate_pal(pal))
})

test_that("validate_pal rejects missing shells (V3)", {
  pal <- pal_fixture_n4()
  pal$shells <- NULL
  expect_error(validate_pal(pal), class = "simpleError")
})

test_that("validate_pal rejects missing core (V4)", {
  pal <- pal_fixture_n4()
  pal$core <- NULL
  expect_error(validate_pal(pal), class = "simpleError")
})

test_that("validate_pal rejects wrong core type (V5)", {
  pal <- pal_fixture_n4()
  pal$core <- 42
  expect_error(validate_pal(pal), class = "simpleError")
})

test_that("validate_pal rejects wrong shells type (V6)", {
  pal <- pal_fixture_n4()
  pal$shells <- 1:4
  expect_error(validate_pal(pal), class = "simpleError")
})

test_that("validate_pal rejects wrong mapping_pack_id type (V7)", {
  pal <- pal_fixture_n4()
  pal$mapping_pack_id <- 0L
  expect_error(validate_pal(pal), class = "simpleError")
})

test_that("validate_pal does not check active_singularities (V8)", {
  # v0.1 has no active_singularities field — validation should pass
  pal <- pal_fixture_n4()
  expect_invisible(validate_pal(pal))
})

test_that("validate_pal does not check phase (V9)", {
  # v0.1 has no phase field — validation should pass
  pal <- pal_fixture_n4()
  expect_invisible(validate_pal(pal))
})

test_that("validate_pal has no rho+theta logic (V10)", {
  # v0.1 does not implement rho+theta conservation
  # This test verifies validate_pal returns without error on any valid state
  pal <- pal_fixture_n4()
  expect_invisible(validate_pal(pal))
})
