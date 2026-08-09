# Test: gradient emergence — layered expansion, not matrix filling.
# Each batch is one gradient layer; the matrix is only an observation
# window. Structural invariants are verified (not guessed values).

test_that("gradient_layers builds a position stream with ring sizes 4k", {
  g <- gradient_layers(3L)
  expect_s3_class(g, "visualr_gradient_layers")
  expect_length(g, 4L)
  expect_identical(nrow(g[[1L]]), 1L)   # center
  expect_identical(nrow(g[[2L]]), 4L)   # k=1
  expect_identical(nrow(g[[3L]]), 8L)   # k=2
  expect_identical(nrow(g[[4L]]), 12L)  # k=3
  # center is (0,0)
  expect_identical(g[[1L]]$x, 0L)
  expect_identical(g[[1L]]$y, 0L)
})

test_that("gradient_layers validates depth", {
  expect_error(gradient_layers(-1L), "non-negative")
  expect_error(gradient_layers(1.5), "non-negative|integer")
})

test_that("each ring has central inversion symmetry", {
  g <- gradient_layers(4L)
  for (k in 2:5) {
    ring <- g[[k]]
    keys <- paste(ring$x, ring$y, sep = ",")
    inv <- paste(-ring$x, -ring$y, sep = ",")
    expect_setequal(keys, inv)
  }
})

test_that("emerge_weight decays with layer and is structural, not statistical", {
  expect_identical(emerge_weight(0L, 1L), 1)
  expect_identical(emerge_weight(1L, 4L), 0.5)
  expect_identical(emerge_weight(2L, 8L), 0.25)
  expect_identical(emerge_weight(1L, 4L, model = "uniform"), 1)
  expect_error(emerge_weight(-1L, 4L), "non-negative")
  expect_error(emerge_weight(1L, 0L), "positive")
})

test_that("emerge_by_layers consumes batches incrementally", {
  e <- emerge_by_layers(2L)
  expect_length(e$layers, 3L)
  expect_identical(nrow(e$depth_map), 1L + 4L + 8L)
  expect_identical(e$needs_extension, FALSE)
  # gradient depth equals layer index
  expect_true(all(e$depth_map$depth == rep(0:2, c(1L, 4L, 8L))))
  # symbol assignment: center is e (singularity first batch), outward
  expect_identical(unique(e$depth_map$symbol[e$depth_map$depth == 0L]), "e")
  expect_identical(unique(e$depth_map$symbol[e$depth_map$depth == 1L]), "D")
  expect_identical(unique(e$depth_map$symbol[e$depth_map$depth == 2L]), "C")
})

test_that("deep expansion reports symbol extension need instead of inventing", {
  e <- emerge_by_layers(6L)  # symbols only reach depth 4
  expect_true(e$needs_extension)
  expect_true(all(is.na(e$depth_map$symbol[e$depth_map$depth == 5L])))
})

test_that("projection window shows NA corners and keeps symbols", {
  e <- emerge_by_layers(2L)
  m <- project_gradient_window(e, radius = 2L)
  expect_identical(dim(m), c(5L, 5L))
  # corners outside the diamond are NA
  expect_true(is.na(m[1L, 1L]))
  expect_true(is.na(m[5L, 5L]))
  # center is e
  expect_identical(m[3L, 3L], "e")
  # layer 1 ring: four D
  expect_identical(sum(m == "D", na.rm = TRUE), 4L)
  expect_identical(sum(m == "C", na.rm = TRUE), 8L)
})

test_that("verify_gradient_emergence checks structural invariants", {
  e <- emerge_by_layers(3L)
  v <- verify_gradient_emergence(e)
  expect_true(v$layer_size_ok)
  expect_true(v$center_ok)
  expect_true(v$inversion_ok)
  expect_true(v$depth_ok)
  expect_true(v$ok)
})
