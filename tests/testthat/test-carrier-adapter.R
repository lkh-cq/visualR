# Test file: carrier transfer adapter (TCN reference, C + A)
# TCN downsample discipline: match = pass-through, mismatch = explicit
# adaptation. typed view discipline (A): 11x11 is the S_5 carrier view,
# reachable only through carrier_11x11(), never through padding.

test_that("same width is identity pass-through", {
  m <- matrix(1:9, 3L, 3L)
  a <- carrier_adapter(m, 3L, 3L)
  expect_true(a$matched)
  expect_equal(a$rule, "identity_pass_through")
  expect_equal(a$adapted, m)
})

test_that("3x3 -> 4x4 pads bottom-right to width 4", {
  m <- matrix(1:9, 3L, 3L)
  a <- carrier_adapter(m, 3L, 4L)
  expect_equal(dim(a$adapted), c(4L, 4L))
  expect_equal(a$rule, "border_pad_3to4")
  expect_equal(a$adapted[1:3, 1:3], m)      # original preserved
  expect_true(all(a$adapted[4, ] == 0L))    # new row zero
  expect_true(all(a$adapted[, 4] == 0L))    # new col zero
})

test_that("4x4 -> 3x3 crops the border back", {
  m <- matrix(1:16, 4L, 4L)
  a <- carrier_adapter(m, 4L, 3L)
  expect_equal(dim(a$adapted), c(3L, 3L))
  expect_equal(a$rule, "border_crop_4to3")
  expect_equal(a$adapted, m[1:3, 1:3])
})

test_that("pad then crop round-trips the original 3x3", {
  m <- matrix(1:9, 3L, 3L)
  up <- carrier_adapter(m, 3L, 4L)$adapted
  down <- carrier_adapter(up, 4L, 3L)$adapted
  expect_equal(down, m)
})

test_that("3x3 -> 11x11 is refused (typed view discipline)", {
  expect_error(carrier_adapter(matrix(1:9, 3L, 3L), 3L, 11L),
               "carrier_11x11")
})

test_that("illegal widths fail closed", {
  expect_error(carrier_adapter(matrix(1:25, 5L, 5L), 5L, 5L),
               "Legal widths")
  expect_error(carrier_adapter(matrix(1:9, 3L, 3L), 3L, 5L),
               "Legal widths")
})

test_that("width mismatch between matrix and from_width fails closed", {
  expect_error(carrier_adapter(matrix(1:16, 4L, 4L), 3L, 4L),
               "from_width")
  expect_error(carrier_adapter(matrix(1:9, 3L, 3L), 4L, 4L),
               "from_width")
})

test_that("rules are named explicitly (auditable)", {
  expect_equal(carrier_adapter(matrix(1:9, 3L, 3L), 3L, 3L)$rule,
               "identity_pass_through")
  expect_equal(carrier_adapter(matrix(1:9, 3L, 3L), 3L, 4L)$rule,
               "border_pad_3to4")
  expect_equal(carrier_adapter(matrix(1:16, 4L, 4L), 4L, 3L)$rule,
               "border_crop_4to3")
})

test_that("print method renders without error", {
  expect_invisible(print(carrier_adapter(matrix(1:9, 3L, 3L), 3L, 3L)))
})
