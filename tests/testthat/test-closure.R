# Test file: closure gate + emergence operators
# Ported from mapping_pack.py closure() / compute() / op_orbit_rotate().
# Cross-verified against Python reference.

# S_4 canonical jiugong
s4_grid <- function() {
  matrix(c("A", "B", "C", "D", "e", "D", "C", "B", "A"),
         3, 3, byrow = TRUE)
}

test_that("closure of canonical S_4 is closed", {
  expect_equal(closure_jiugong(s4_grid()), "closed")
})

test_that("closure of S_0 (1x1 center only, padded? no—must be 3x3)", {
  # A single-center state is not a 3x3 matrix; closure requires 3x3
  expect_error(closure_jiugong(matrix("e", 1, 1)), "3x3")
})

test_that("closure of asymmetric matrix is recurse", {
  M <- s4_grid()
  M[1, 1] <- "D"  # breaks central inversion symmetry (mirror is (3,3)="A")
  expect_equal(closure_jiugong(M), "recurse")
})

test_that("closure of orbit-rotated matrix is closed (Python-verified)", {
  M <- compute_jiugong(s4_grid(), "orbit_rotate")
  expect_equal(closure_jiugong(M), "closed")
})

test_that("closure rejects non-3x3", {
  expect_error(closure_jiugong(matrix(1:4, 2, 2)), "3x3")
})

test_that("closure rejects non-canonical symbols (spec hole)", {
  # Frozen symbols are A/B/C/D/e (+ stripped markers a/b/c/d from gamma)
  weird <- matrix(c("X", "Y", "Z", "W", "q", "W", "Z", "Y", "X"), 3, 3, byrow = TRUE)
  expect_equal(closure_jiugong(weird), "transient")
})

test_that("closure rejects empty-string symbols", {
  empty <- matrix(c("", "", "", "", "e", "", "", "", ""), 3, 3, byrow = TRUE)
  expect_equal(closure_jiugong(empty), "transient")
})

test_that("closure rejects NA cells", {
  na_grid <- matrix(c("A", "B", "C", "D", NA, "D", "C", "B", "A"), 3, 3, byrow = TRUE)
  expect_equal(closure_jiugong(na_grid), "transient")
})

test_that("closure accepts gamma output (stripped markers a/b/c/d)", {
  g <- gamma_field(new_pal_state(c("A", "B", "C", "D"), "e"))
  expect_equal(closure_jiugong(g), "closed")
})

test_that("identity operator preserves matrix", {
  M <- s4_grid()
  expect_equal(compute_jiugong(M, "identity"), M)
})

test_that("orbit_rotate rotates D->C->B->A->D", {
  M <- s4_grid()
  out <- compute_jiugong(M, "orbit_rotate")
  # D's positions get A's values ("A")
  expect_equal(out[2, 1], "A")  # D orbit head
  expect_equal(out[2, 3], "A")  # D orbit tail
  # C's positions get D's values ("D")
  expect_equal(out[1, 3], "D")  # C orbit head
  expect_equal(out[3, 1], "D")  # C orbit tail
  # center unchanged
  expect_equal(out[2, 2], "e")
})

test_that("compute rejects unknown operator", {
  expect_error(compute_jiugong(s4_grid(), "nope"), "Unknown")
})

test_that("compute rejects non-matrix", {
  expect_error(compute_jiugong("A"), "3x3")
})

test_that("register_operator adds custom operator", {
  register_operator("flip_diag", function(M, pack) t(M))
  M <- s4_grid()
  out <- compute_jiugong(M, "flip_diag")
  expect_equal(out[1, 3], "C")  # transposed: (1,3) was (3,1)="C"
  expect_equal(out[3, 1], "C")  # (3,1) was (1,3)="C"
})

test_that("register_operator validates inputs", {
  expect_error(register_operator("", function(M, pack) M), "non-empty")
  expect_error(register_operator("x", "not-a-fn"), "function")
})

test_that("orbit_rotate snapshot semantics: all reads from same snapshot", {
  # With copy-on-modify, out is a copy; modifying out during loop
  # must not affect subsequent reads (they use `snapshot`).
  M <- s4_grid()
  out <- compute_jiugong(M, "orbit_rotate")
  # B's positions should get C's ORIGINAL values ("C"), not the
  # just-written D values — snapshot semantics
  expect_equal(out[1, 2], "C")  # B orbit head: from C orbit (original "C")
  expect_equal(out[3, 2], "C")  # B orbit tail
})

test_that("cross-verified with Python: identity and orbit_rotate", {
  # Python: compute(M4, "orbit_rotate") rotates D<-A, C<-D, B<-C, A<-B
  M <- s4_grid()
  out <- compute_jiugong(M, "orbit_rotate")
  # Python op_orbit_rotate: orbit_map = {"D":"A","C":"D","B":"C","A":"B"}
  # D gets A("A"), C gets D("D"), B gets C("C"), A gets B("B")
  expect_equal(out[2, 1], "A")
  expect_equal(out[2, 3], "A")
  expect_equal(out[1, 3], "D")
  expect_equal(out[3, 1], "D")
  expect_equal(out[1, 2], "C")
  expect_equal(out[3, 2], "C")
  expect_equal(out[1, 1], "B")
  expect_equal(out[3, 3], "B")
})
