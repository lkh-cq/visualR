# Test file: unfold_pal / fold_pal
# TDD RED phase — tests written before implementation

test_that("unfold_pal produces palindrome for S_4 (U1)", {
  pal <- pal_fixture_n4()
  result <- unfold_pal(pal)
  expect_equal(result, c("A", "B", "C", "D", "E", "D", "C", "B", "A"))
})

test_that("unfold_pal produces single element for S_0 (U2)", {
  pal <- pal_fixture_n0()
  result <- unfold_pal(pal)
  expect_equal(result, c("X"))
})

test_that("unfold_pal produces palindrome for S_1 (U3)", {
  pal <- pal_fixture_n1()
  result <- unfold_pal(pal)
  expect_equal(result, c("A", "B", "A"))
})

test_that("unfold_pal length is 2*length(shells)+1 (U4)", {
  pal <- pal_fixture_n4()
  result <- unfold_pal(pal)
  expect_length(result, 2 * length(pal$shells) + 1)
})

test_that("unfold_pal output is a palindrome (U5)", {
  pal <- pal_fixture_n4()
  result <- unfold_pal(pal)
  expect_equal(result, rev(result))
})

test_that("fold_pal(unfold_pal(S_0)) round-trips (U6)", {
  pal <- pal_fixture_n0()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("fold_pal(unfold_pal(S_4)) round-trips (U7)", {
  pal <- pal_fixture_n4()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("fold_pal(unfold_pal(S_1)) round-trips (U8)", {
  pal <- pal_fixture_n1()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("fold_pal rejects even-length input (U9)", {
  expect_error(
    fold_pal(c("A", "B")),
    class = "simpleError"
  )
})

test_that("fold_pal rejects non-palindrome (U10)", {
  expect_error(
    fold_pal(c("A", "B", "C")),
    class = "simpleError"
  )
})

test_that("fold_pal rejects non-character input (U11)", {
  expect_error(
    fold_pal(c(1, 2, 1)),
    class = "simpleError"
  )
})

test_that("fold_pal only reads unfolded path [藏归分离] (U12)", {
  # S_custom has non-default metadata.
  # fold_pal(unfold_pal(S_custom)) should return DEFAULT metadata,
  # proving fold_pal does not access the hidden original object.
  pal_custom <- pal_fixture_n4_custom()
  result <- fold_pal(unfold_pal(pal_custom))

  # shells and core are recoverable from the unfolded path
  expect_equal(result$shells, pal_custom$shells)
  expect_equal(result$core, pal_custom$core)

  # metadata should be DEFAULT, not custom — this proves藏归分离
  expect_equal(result$mapping_pack_id, "pal-jiugong-v0.1")
  expect_equal(result$provenance, list())
})

test_that("fold_pal with custom metadata params (U13)", {
  pal_custom <- pal_fixture_n4_custom()
  result <- fold_pal(
    unfold_pal(pal_custom),
    mapping_pack_id = "custom-v0.2",
    provenance = list(clock = 42L, source = "test")
  )
  expect_equal(result$mapping_pack_id, "custom-v0.2")
  expect_equal(result$provenance, list(clock = 42L, source = "test"))
})

test_that("fold_pal handles empty shells (U14)", {
  result <- fold_pal(c("X"))
  expect_equal(result$shells, character(0))
  expect_equal(result$core, "X")
})
