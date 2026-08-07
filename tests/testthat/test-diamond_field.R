# Test file: diamond_field
# TDD RED phase — tests written before implementation
# Audit ruling I2: output is ORDER (lambda = n - |p-c|_1), NOT distance.
# Single direction: no diamond_to_pal() inverse exists.

test_that("diamond_field produces 9x9 matrix for S_4 (D1)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  expect_s3_class(dm, "visualr_diamond")
  expect_equal(dim(dm$matrix), c(9L, 9L))
})

test_that("diamond_field produces 1x1 matrix for S_0 (D2)", {
  pal <- pal_fixture_n0()
  dm <- diamond_field(pal)
  expect_s3_class(dm, "visualr_diamond")
  expect_equal(dim(dm$matrix), c(1L, 1L))
})

test_that("diamond_field produces 3x3 matrix for S_1 (D3)", {
  pal <- pal_fixture_n1()
  dm <- diamond_field(pal)
  expect_equal(dim(dm$matrix), c(3L, 3L))
})

test_that("diamond_field produces 5x5 matrix for S_2 (D4)", {
  pal <- pal_fixture_n2()
  dm <- diamond_field(pal)
  expect_equal(dim(dm$matrix), c(5L, 5L))
})

test_that("center value equals n for S_4 (D5)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  # n=4, center at (5,5), order = 4 - 0 = 4
  expect_equal(dm$matrix[5, 5], 4)
})

test_that("center value equals 0 for S_0 (D6)", {
  pal <- pal_fixture_n0()
  dm <- diamond_field(pal)
  # n=0, center at (1,1), order = 0 - 0 = 0
  expect_equal(dm$matrix[1, 1], 0)
})

test_that("center value equals n for S_1 (D7)", {
  pal <- pal_fixture_n1()
  dm <- diamond_field(pal)
  # n=1, center at (2,2), order = 1
  expect_equal(dm$matrix[2, 2], 1)
})

test_that("diamond area is 1+2n(n+1) for S_4 (D8)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  # n=4: area = 1 + 2*4*5 = 41
  non_na <- sum(!is.na(dm$matrix))
  expect_equal(non_na, 41)
})

test_that("diamond area is 1 for S_0 (D9)", {
  pal <- pal_fixture_n0()
  dm <- diamond_field(pal)
  non_na <- sum(!is.na(dm$matrix))
  expect_equal(non_na, 1)
})

test_that("diamond area is 5 for S_1 (D10)", {
  pal <- pal_fixture_n1()
  dm <- diamond_field(pal)
  # n=1: area = 1 + 2*1*2 = 5
  non_na <- sum(!is.na(dm$matrix))
  expect_equal(non_na, 5)
})

test_that("diamond area is 13 for S_2 (D11)", {
  pal <- pal_fixture_n2()
  dm <- diamond_field(pal)
  # n=2: area = 1 + 2*2*3 = 13
  non_na <- sum(!is.na(dm$matrix))
  expect_equal(non_na, 13)
})

test_that("values are order not distance (D12)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  # Center (5,5): dist=0, order=4
  # Adjacent (4,5): dist=1, order=3 (NOT distance=1)
  expect_equal(dm$matrix[4, 5], 3)
  # Two steps (3,5): dist=2, order=2
  expect_equal(dm$matrix[3, 5], 2)
  # Edge of diamond (1,5): dist=4, order=0
  expect_equal(dm$matrix[1, 5], 0)
})

test_that("S_1 diamond: center=1, edges=0, corners=NA (D13)", {
  pal <- pal_fixture_n1()
  dm <- diamond_field(pal)
  # 3x3 matrix:
  #   NA  0  NA
  #    0  1   0
  #   NA  0  NA
  expect_equal(dm$matrix[2, 2], 1)
  expect_equal(dm$matrix[1, 2], 0)
  expect_equal(dm$matrix[3, 2], 0)
  expect_equal(dm$matrix[2, 1], 0)
  expect_equal(dm$matrix[2, 3], 0)
  expect_true(is.na(dm$matrix[1, 1]))
  expect_true(is.na(dm$matrix[1, 3]))
  expect_true(is.na(dm$matrix[3, 1]))
  expect_true(is.na(dm$matrix[3, 3]))
})

test_that("matrix is point-symmetric around center (D14)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  size <- 9
  center <- 5
  for (i in 1:size) {
    for (j in 1:size) {
      mirror_i <- 2 * center - i
      mirror_j <- 2 * center - j
      expect_equal(dm$matrix[i, j], dm$matrix[mirror_i, mirror_j])
    }
  }
})

test_that("edge of diamond has order 0 (D15)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  # Edge cells: distance = n = 4 from center (5,5)
  # (1,5), (5,1), (5,9), (9,5) — all should be 0
  expect_equal(dm$matrix[1, 5], 0)
  expect_equal(dm$matrix[5, 1], 0)
  expect_equal(dm$matrix[5, 9], 0)
  expect_equal(dm$matrix[9, 5], 0)
})

test_that("outside diamond is NA (D16)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  # Corners of 9x9 matrix: distance = 8 > n=4
  expect_true(is.na(dm$matrix[1, 1]))
  expect_true(is.na(dm$matrix[1, 9]))
  expect_true(is.na(dm$matrix[9, 1]))
  expect_true(is.na(dm$matrix[9, 9]))
})

test_that("diamond_field returns visualr_diamond class (D17)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  expect_s3_class(dm, "visualr_diamond")
})

test_that("center field is correct for S_4 (D18)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  expect_equal(dm$center, c(5L, 5L))
})

test_that("center field is correct for S_0 (D19)", {
  pal <- pal_fixture_n0()
  dm <- diamond_field(pal)
  expect_equal(dm$center, c(1L, 1L))
})

test_that("radius field equals n (D20)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  expect_equal(dm$radius, 4L)
})

test_that("n field equals length(shells) (D21)", {
  pal <- pal_fixture_n2()
  dm <- diamond_field(pal)
  expect_equal(dm$n, 2L)
})

test_that("matrix is numeric (D22)", {
  pal <- pal_fixture_n4()
  dm <- diamond_field(pal)
  expect_type(dm$matrix, "double")
})

# ── v0.2.1 P1: lazy diamond_at ──────────────────────────────────────

test_that("diamond_at center is n", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_equal(diamond_at(pal, 0, 0), 4L)
})

test_that("diamond_at matches materialized field", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  f <- diamond_field(pal)
  n <- 4L
  for (x in -4:4) {
    for (y in -4:4) {
      expected <- f$matrix[n + 1 + y, n + 1 + x]
      expect_equal(diamond_at(pal, x, y),
                   if (is.na(expected)) NA_integer_ else as.integer(expected),
                   info = sprintf("(%d,%d)", x, y))
    }
  }
})

test_that("diamond_at returns NA outside diamond", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_true(is.na(diamond_at(pal, 5, 0)))
  expect_true(is.na(diamond_at(pal, 0, 5)))
  expect_true(is.na(diamond_at(pal, 3, 3)))
})
