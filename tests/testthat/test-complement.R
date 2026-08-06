# Test file: complement_pal / mirror_addr / locate
# Frozen symmetry operators (sanyuan-runtime v0.2 spec)

test_that("complement default is self-complement (C(x)=x)", {
  pal <- pal_fixture_n4()
  comp <- complement_pal(pal)
  expect_equal(comp$shells, pal$shells)
  expect_equal(comp$core, pal$core)
})

test_that("complement with custom table maps symbols", {
  pal <- new_pal_state(shells = c("A", "B", "C", "D"), core = "e")
  comp <- complement_pal(pal, table = c(A = "T", T = "A", B = "G", G = "B"))
  expect_equal(comp$shells, c("T", "G", "C", "D"))
  expect_equal(comp$core, "e")
})

test_that("complement table must be an involution (C^2 = I)", {
  pal <- pal_fixture_n4()
  # A->T but T->G breaks involution
  expect_error(
    complement_pal(pal, table = c(A = "T", T = "G", G = "A")),
    "involution"
  )
})

test_that("complement preserves metadata", {
  pal <- pal_fixture_n4_custom()
  comp <- complement_pal(pal, table = c(A = "T", T = "A"))
  expect_equal(comp$mapping_pack_id, pal$mapping_pack_id)
  expect_equal(comp$provenance, pal$provenance)
})

test_that("complement C^2 = I on custom table", {
  pal <- pal_fixture_n4()
  table <- c(A = "T", T = "A", B = "G", G = "B", C = "C", D = "D")
  once <- complement_pal(pal, table = table)
  twice <- complement_pal(once, table = table)
  expect_equal(twice$shells, pal$shells)
  expect_equal(twice$core, pal$core)
})

test_that("complement rejects non-character table", {
  pal <- pal_fixture_n4()
  expect_error(complement_pal(pal, table = c(1, 2, 3)), "named character")
})

test_that("mirror_addr inverts corners (Σ^2 = I)", {
  expect_equal(mirror_addr(1L, 1L), c(3L, 3L))
  expect_equal(mirror_addr(1L, 3L), c(3L, 1L))
  expect_equal(mirror_addr(3L, 1L), c(1L, 3L))
  expect_equal(mirror_addr(3L, 3L), c(1L, 1L))
})

test_that("mirror_addr center is fixed point", {
  expect_equal(mirror_addr(2L, 2L), c(2L, 2L))
})

test_that("mirror_addr Σ^2 = I for all 9 cells", {
  for (r in 1:3) {
    for (c in 1:3) {
      m1 <- mirror_addr(r, c)
      m2 <- mirror_addr(m1[1], m1[2])
      expect_equal(m2, c(r, c), info = sprintf("(r=%d,c=%d)", r, c))
    }
  }
})

test_that("mirror_addr rejects out-of-range", {
  expect_error(mirror_addr(0L, 1L), "1..3")
  expect_error(mirror_addr(4L, 1L), "1..3")
  expect_error(mirror_addr(1L, 9L), "1..3")
})

test_that("locate returns fourth-dimension mapping", {
  loc <- locate("D")
  expect_equal(loc$head_index, 4L)
  expect_equal(loc$tail_index, 6L)
  expect_equal(loc$head_addr, c(2L, 1L))
  expect_equal(loc$tail_addr, c(2L, 3L))
})

test_that("locate center e is self-paired", {
  loc <- locate("e")
  expect_equal(loc$head_index, 5L)
  expect_equal(loc$tail_index, 5L)
  expect_equal(loc$head_addr, c(2L, 2L))
  expect_equal(loc$mirror_tail_addr, c(2L, 2L))
})

test_that("locate rejects unknown symbol", {
  expect_error(locate("Z"), "not in the fourth-dimension")
})
