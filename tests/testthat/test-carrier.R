# Test file: S_5 11x11 neighborhood transformation carrier
# Frozen spec: references/s5-carrier-v02.md + README (2026-08-05).
# Key properties must ALL hold (these define the spec; the matrix was
# verified 0/121 mismatches at freeze time).

test_that("carrier is 11x11", {
  M <- carrier_11x11()
  expect_equal(dim(M), c(11L, 11L))
  Mi <- carrier_11x11(as_symbol = TRUE)
  expect_equal(dim(Mi), c(11L, 11L))
})

test_that("canonical form is NUMERIC orders 0..5 (letters are placeholders)", {
  # Frozen decision 2026-08-05: matrix = 2D slice of dimension expansion;
  # cell value = ORDER (dimension index), letters are display-only.
  M <- carrier_11x11()
  expect_true(is.integer(M) || is.numeric(M))
  expect_true(all(M %in% 0:5))
})

test_that("center is order 0 at (6,6)", {
  M <- carrier_11x11()
  expect_equal(M[6, 6], 0L)
  Ms <- carrier_11x11(as_symbol = TRUE)
  expect_equal(Ms[6, 6], "F")
})

test_that("center 8-neighborhood: cross E + diagonal D", {
  M <- carrier_11x11(as_symbol = TRUE)
  expect_equal(M[5, 6], "E")  # up
  expect_equal(M[6, 5], "E")  # left
  expect_equal(M[6, 7], "E")  # right
  expect_equal(M[7, 6], "E")  # down
  expect_equal(M[5, 5], "D")  # up-left
  expect_equal(M[5, 7], "D")  # up-right
  expect_equal(M[7, 5], "D")  # down-left
  expect_equal(M[7, 7], "D")  # down-right
})

test_that("center row is 11-position palindrome A B C D E F E D C B A", {
  M <- carrier_11x11(as_symbol = TRUE)
  expect_equal(as.vector(M[6, ]),
               c("A","B","C","D","E","F","E","D","C","B","A"))
})

test_that("every row and column is a palindrome", {
  M <- carrier_11x11(as_symbol = TRUE)
  for (r in 1:11) {
    expect_equal(as.vector(M[r, ]), rev(as.vector(M[r, ])),
                 info = paste("row", r))
  }
  for (c in 1:11) {
    expect_equal(as.vector(M[, c]), rev(as.vector(M[, c])),
                 info = paste("col", c))
  }
})

test_that("row max LETTER (alphabet position) = 6 - distance from center (0-indexed)", {
  # "每行最大字母 = 6 - 行距(中心行 F,边缘 A)" — max letter by ALPHABET
  # position: A=1..F=6. Center row has F (pos 6), edge rows only A (pos 1).
  M <- carrier_11x11(as_symbol = TRUE)
  pos_of <- c(A = 1, B = 2, C = 3, D = 4, E = 5, F = 6)
  for (r in 1:11) {
    center_dist <- abs(r - 6L)  # 0-indexed distance from center row
    row_pos <- pos_of[as.vector(M[r, ])]
    expect_equal(max(row_pos), 6L - center_dist,
                 info = paste("row", r, "center_dist", center_dist))
  }
})

test_that("Manhattan rings 0-3 are pure distance (center row)", {
  M <- carrier_11x11(as_symbol = TRUE)
  # center row positions: F(0) E(1) D(2) C(3) at distances 0..3
  expect_equal(M[6, 6], "F")
  expect_equal(M[6, 7], "E")
  expect_equal(M[6, 8], "D")
  expect_equal(M[6, 9], "C")
})

test_that("diagonal compression: 0-idx (2,2) = D not B (K3)", {
  # Document: "(4,4) Manhattan 4 should be B(4) but = D(2): diagonal
  # compressed 3 layers". 0-indexed (2,2) has Manhattan 4; pure distance
  # would be B(4), but the pure-diagonal rule compresses it to D(2).
  # 0-indexed (2,2) -> 1-indexed (6-2, 6-2) = (4,4).
  M <- carrier_11x11(as_symbol = TRUE)
  expect_equal(M[4, 4], "D")
})

test_that("edge rows/cols are all A", {
  M <- carrier_11x11(as_symbol = TRUE)
  expect_true(all(M[1, ] == "A"))
  expect_true(all(M[11, ] == "A"))
  expect_true(all(M[, 1] == "A"))
  expect_true(all(M[, 11] == "A"))
})

test_that("chessboard signature: even rows A/B alternate, odd rows palindrome", {
  M <- carrier_11x11(as_symbol = TRUE)
  # row 2 (1-indexed, even position): A B A B A B A B A B A
  expect_equal(as.vector(M[2, ]),
               c("A","B","A","B","A","B","A","B","A","B","A"))
  # row 3 (odd position): A A B C B C B C B A A (palindrome w/ core B C)
  expect_equal(as.vector(M[3, ]),
               c("A","A","B","C","B","C","B","C","B","A","A"))
})

test_that("carrier_order validates range (internal)", {
  expect_error(visualR:::carrier_order(6L, 0L), "0..5")
  expect_error(visualR:::carrier_order(-1L, 0L), "0..5")
})

test_that("carrier_order matches carrier_11x11 cell values (internal)", {
  M <- carrier_11x11()
  for (r in 1:11) {
    for (c in 1:11) {
      expect_equal(M[r, c], visualR:::carrier_order(abs(r - 6L), abs(c - 6L)),
                   info = sprintf("cell (%d,%d)", r, c))
    }
  }
})

test_that("full matrix has 121 cells; numeric canonical + A-F symbols", {
  M <- carrier_11x11()
  expect_equal(length(M), 121L)
  expect_true(all(M %in% 0:5))
  Ms <- carrier_11x11(as_symbol = TRUE)
  expect_true(all(Ms %in% c("A", "B", "C", "D", "E", "F")))
})
