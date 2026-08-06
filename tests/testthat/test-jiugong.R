# Test file: pal_to_jiugong / jiugong_to_pal
# TDD RED phase — tests written before implementation
# Audit ruling R4: PAL jiugong mapping is separate from spatial window extraction

test_that("pal_to_jiugong produces 3x3 matrix for S_4 (J1)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  expect_s3_class(jg, "visualr_jiugong")
  expect_equal(dim(jg$grid), c(3L, 3L))
})

test_that("pal_to_jiugong produces 1x1 matrix for S_0 (J2)", {
  pal <- pal_fixture_n0()
  jg <- pal_to_jiugong(pal)
  expect_s3_class(jg, "visualr_jiugong")
  expect_equal(dim(jg$grid), c(1L, 1L))
  expect_equal(jg$grid[1, 1], "X")
})

test_that("pal_to_jiugong produces 5x5 matrix for S_12 (J3)", {
  pal <- pal_fixture_n12()
  jg <- pal_to_jiugong(pal)
  expect_s3_class(jg, "visualr_jiugong")
  expect_equal(dim(jg$grid), c(5L, 5L))
})

test_that("pal_to_jiugong fills row-major from unfolded palindrome (J4)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  # unfold_pal(S4) = c("A","B","C","D","E","D","C","B","A")
  # Row-major fill into 3x3:
  #   A B C
  #   D E D
  #   C B A
  expected <- matrix(
    c("A", "B", "C",
      "D", "E", "D",
      "C", "B", "A"),
    nrow = 3, ncol = 3, byrow = TRUE
  )
  expect_equal(jg$grid, expected)
})

test_that("pal_to_jiugong rejects non-perfect-square unfold length (J5)", {
  # S_2: unfold length = 5, sqrt(5) is not integer
  pal <- pal_fixture_n2()
  expect_error(
    pal_to_jiugong(pal),
    class = "simpleError"
  )
})

test_that("pal_to_jiugong returns visualr_jiugong class (J6)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  expect_s3_class(jg, "visualr_jiugong")
})

test_that("pal_to_jiugong inherits mapping_pack_id (J7)", {
  pal <- pal_fixture_n4_custom()
  jg <- pal_to_jiugong(pal)
  expect_equal(jg$mapping_pack_id, "custom-v0.2")
})

test_that("pal_to_jiugong default mapping_pack_id (J7b)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  expect_equal(jg$mapping_pack_id, "pal-jiugong-v0.1")
})

test_that("grid center equals core (J8)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  # 3x3 center is [2,2]
  expect_equal(jg$grid[2, 2], "E")
})

test_that("grid is point-symmetric (palindrome property) (J9)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  # Point symmetry: grid[i,j] == grid[4-i, 4-j] for 3x3
  k <- 3
  for (i in 1:k) {
    for (j in 1:k) {
      expect_equal(jg$grid[i, j], jg$grid[k + 1 - i, k + 1 - j])
    }
  }
})

test_that("jiugong_to_pal round-trips S_4 (J10)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  result <- jiugong_to_pal(jg)
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("jiugong_to_pal round-trips S_0 (J11)", {
  pal <- pal_fixture_n0()
  jg <- pal_to_jiugong(pal)
  result <- jiugong_to_pal(jg)
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("jiugong_to_pal round-trips S_12 (J12)", {
  pal <- pal_fixture_n12()
  jg <- pal_to_jiugong(pal)
  result <- jiugong_to_pal(jg)
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("jiugong_to_pal preserves mapping_pack_id (J13)", {
  pal <- pal_fixture_n4_custom()
  jg <- pal_to_jiugong(pal)
  result <- jiugong_to_pal(jg)
  expect_equal(result$mapping_pack_id, "custom-v0.2")
})

test_that("jiugong_to_pal rejects non-jiugong input (J14)", {
  expect_error(
    jiugong_to_pal(list(grid = matrix(1:4, 2, 2))),
    class = "simpleError"
  )
})

test_that("jiugong_to_pal with explicit mapping_pack_id override (J15)", {
  pal <- pal_fixture_n4()
  jg <- pal_to_jiugong(pal)
  result <- jiugong_to_pal(jg, mapping_pack_id = "override-v0.3")
  expect_equal(result$mapping_pack_id, "override-v0.3")
})
