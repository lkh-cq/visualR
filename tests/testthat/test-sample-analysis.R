# Test: sample topology analysis — symmetries, orbits, centers.
# 3x3 / 4x4 are registered as evidence; the analysis must reproduce
# the structural facts from the external review (2026-08-09).

M3 <- matrix(c("A", "B", "C", "D", "e", "D", "C", "B", "A"),
             3, 3, byrow = TRUE)
M4 <- matrix(c("A", "B", "C", "D", "B", "C", "e", "C",
               "C", "e", "C", "B", "D", "C", "B", "A"),
             4, 4, byrow = TRUE)

test_that("3x3 has central inversion but NOT transpose symmetry", {
  s <- detect_symmetries(M3)
  expect_true(s$inversion_ok)
  expect_false(s$transpose_ok)
})

test_that("4x4 has BOTH transpose and central inversion symmetry", {
  s <- detect_symmetries(M4)
  expect_true(s$inversion_ok)
  expect_true(s$transpose_ok)
})

test_that("3x3 orbit partition yields 5 orbits with no label reuse", {
  o <- orbit_partition(M3)
  expect_identical(nrow(o), 9L)
  expect_identical(length(unique(o$orbit)), 5L)
  expect_identical(length(unique(o$label)), 5L)
  r <- label_reuse(o)
  expect_false(r$has_reuse)
  # A orbit has exactly the two corners (1,1),(3,3)
  a <- o[o$label == "A", ]
  expect_setequal(paste(a$row, a$col, sep = ","), c("1,1", "3,3"))
  # e is the single semantic center
  e <- o[o$label == "e", ]
  expect_identical(nrow(e), 1L)
})

test_that("4x4 orbit partition yields 6 orbits with C label reused", {
  o <- orbit_partition(M4)
  expect_identical(nrow(o), 16L)
  expect_identical(length(unique(o$orbit)), 6L)
  expect_identical(length(unique(o$label)), 5L)
  r <- label_reuse(o)
  expect_true(r$has_reuse)
  expect_true("C" %in% names(r$reused_labels))
  # C appears in exactly two distinct orbits
  expect_length(r$reused_labels$C, 2L)
})

test_that("4x4 B orbit matches the first outer rail addresses", {
  o <- orbit_partition(M4)
  b <- o[o$label == "B", ]
  expect_setequal(paste(b$row, b$col, sep = ","),
                  c("1,2", "2,1", "3,4", "4,3"))
  expect_identical(nrow(b), 4L)
})

test_that("4x4 geometric center set differs from semantic e pair", {
  c <- center_analysis(M4)
  # geometric center = central 2x2 block (4 addresses)
  expect_identical(c$geometric_count, 4L)
  expect_setequal(paste(c$geometric_centers$row, c$geometric_centers$col, sep = ","),
                  c("2,2", "2,3", "3,2", "3,3"))
  # semantic center = e pair on the anti-diagonal (2 addresses)
  expect_identical(c$semantic_count, 2L)
  expect_setequal(paste(c$semantic_centers$row, c$semantic_centers$col, sep = ","),
                  c("2,3", "3,2"))
  # they do NOT coincide: content value cannot replace address
  expect_false(c$coincide)
})

test_that("3x3 geometric and semantic centers coincide", {
  c <- center_analysis(M3)
  expect_identical(c$geometric_count, 1L)
  expect_identical(c$semantic_count, 1L)
  expect_true(c$coincide)
})

test_that("audit_sample_topology summarizes structural evidence", {
  a3 <- audit_sample_topology(M3, name = "3x3")
  a4 <- audit_sample_topology(M4, name = "4x4")
  expect_identical(a3$n_orbits, 5L)
  expect_identical(a4$n_orbits, 6L)
  expect_true(a4$label_reuse_occurred)
  expect_false(a3$label_reuse_occurred)
  expect_match(a3$summary, "5 orbits over 5 labels")
  expect_match(a4$summary, "6 orbits over 5 labels \\(label reuse\\)")
})

test_that("detect_symmetries validates input", {
  expect_error(detect_symmetries(matrix(1:6, 2, 3)), "square matrix")
})
