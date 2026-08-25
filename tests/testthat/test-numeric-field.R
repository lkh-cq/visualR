# Test file: address-bound numeric field (v0.6.2 experimental)

test_that("numeric fields bind values to PAL global addresses", {
  field <- new_numeric_field(
    .numeric_window_fixture(),
    values = c(1, 2, 3, 2, 1),
    value_semantics = "measurement",
    unit = "a.u."
  )

  expect_s3_class(field, "visualr_numeric_field")
  expect_true(validate_numeric_field(field))
  expect_identical(field$address$global_address, 8:12)
  expect_equal(field$value, c(1, 2, 3, 2, 1))
  expect_equal(field$boundary_state, "open")
  expect_equal(field$domain, "path")
  expect_false(anyDuplicated(field$address$address_id) > 0L)
  expect_true(nzchar(field$source_hash))
  expect_true(nzchar(field$mapping_pack$hash))
})

test_that("matrix fields preserve column-major address/value identity", {
  x <- matrix(1:9, nrow = 3L)
  field <- new_numeric_field(
    x,
    value_semantics = "carrier_order",
    unit = "ordinal",
    boundary_state = "closed"
  )

  expect_identical(field$shape, c(3L, 3L))
  expect_equal(field$value, as.numeric(x))
  expect_identical(field$address$row, rep(1:3, 3L))
  expect_identical(field$address$col, rep(1:3, each = 3L))
  expect_equal(length(unique(field$address$address_id)), 9L)
})

test_that("numeric field construction fails closed on ambiguous values", {
  w <- .numeric_window_fixture()
  expect_error(
    new_numeric_field(w, 1:4, "measurement"),
    "one value per address"
  )
  expect_error(
    new_numeric_field(w, letters[1:5], "measurement"),
    "numeric or complex"
  )
  expect_error(
    new_numeric_field(w, c(1, 2, NA, 2, 1), "measurement"),
    "finite"
  )
  expect_error(new_numeric_field(w, 1:5, ""), "value_semantics")
  expect_error(
    new_numeric_field(matrix(1:4, 2L), values = 5:8,
                      value_semantics = "ambiguous",
                      boundary_state = "closed"),
    "already present"
  )
})

test_that("source hash changes when bound values change", {
  w <- .numeric_window_fixture()
  a <- new_numeric_field(w, 1:5, "measurement")
  b <- new_numeric_field(w, c(1:4, 6), "measurement")
  expect_false(identical(a$source_hash, b$source_hash))
})

test_that("numeric field validation rejects post-construction mutation", {
  field <- new_numeric_field(matrix(1:4, 2L),
                             value_semantics = "fixture",
                             boundary_state = "closed")
  field$value[[1L]] <- 99
  expect_error(validate_numeric_field(field), "source hash")

  path <- new_numeric_field(.numeric_window_fixture(), 1:5, "fixture")
  path$address$global_address[[1L]] <- 7L
  expect_error(validate_numeric_field(path), "address coordinates|source hash")
})
