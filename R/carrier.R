# == carrier_11x11: S_5 neighborhood transformation carrier ==========
# STATUS: EXPERIMENTAL (P0-7 ruling 2026-08-07)
#   The mixed Manhattan/Chebyshev piecewise rule below is a FITTED
#   rule that reproduces the current 11x11 example 121/121 -- it is NOT
#   proven to be the unique or general generating law for the carrier
#   topology. It must NOT be treated as a frozen protocol axiom.
#   Naming: carrier11_example_rule_v0.1, status = experimental.
#   A recursive/generative definition must be formally frozen before
#   this becomes an axiom.
#
# Reference: references/s5-carrier-v02.md + README "11x11 carrier".
#
# S_5: path A B C D E F E D C B A (11 positions, F = center singularity)
# Carrier: 11x11 grid, 121 cells = layer diffusion.
# Value = order (F=0, E=1, D=2, C=3, B=4, A=5).
#
# Exact rule (i,j = 0-indexed distance from center (5,5), range 0..5):
#   v(i,j) = min(i+j, 5)             normal zone (min(i,j) <= 1 or saturated)
#            max(i,j)               square zone (min(i,j) >= 2 and i+j <= 6)
#            2*ceil(i/2)            pure diagonal (i==j, min>=2, saturate 5)
#            min(i+j, 5)            square far-corner (i+j > 6 and i != j)
#
# PITFALL (from verification history): center is 0-indexed (5,5),
# NOT (6,6) -- first attempt using abs(r-6) was entirely wrong.
#
# Verified against the frozen spec: 0/121 mismatches (2026-08-05).

# Order alphabet: 0-indexed order -> symbol
CARRIER_ALPHABET <- c("F", "E", "D", "C", "B", "A")  # index 1..6 -> order 0..5

#' @title S_5 11x11 neighborhood transformation carrier
#' @description Build the 11x11 carrier grid for the S_5 neighborhood
#'   transformation (121 cells = layer diffusion).
#'
#'   SEMANTICS (frozen decision 2026-08-05): the matrix is a 2D SLICE of
#'   the palindrome-dimension expansion. Cell value = ORDER (dimension
#'   index) 0..5 (0 at center, increasing outward). Letters F..A are
#'   ONLY readability placeholders for orders 0..5 -- the numeric order
#'   is the canonical form; letters are a display/interop layer used to
#'   align with the frozen spec's alphabet.
#'
#'   Frozen mixed Manhattan/Chebyshev rule: normal zone min(i+j,5);
#'   square zone max(i,j); pure diagonal 2*ceil(i/2); far-corner
#'   min(i+j,5).
#' @param as_symbol logical, return order SYMBOLS (F..A) instead of the
#'   canonical numeric orders 0..5. Default FALSE (numeric is canonical).
#' @return 11x11 matrix: canonical integer orders (0..5) or, when
#'   \code{as_symbol=TRUE}, character symbols (F..A).
#' @examples
#' carrier_11x11()
#' carrier_11x11(as_symbol = TRUE)
carrier_11x11 <- function(as_symbol = FALSE) {
  if (!is.logical(as_symbol) || length(as_symbol) != 1L || is.na(as_symbol)) {
    stop("`as_symbol` must be a single logical.", call. = FALSE)
  }

  M <- matrix(0L, nrow = 11L, ncol = 11L)
  for (r in 1:11) {
    for (c in 1:11) {
      i <- abs(r - 6L)   # 0-indexed distance from center (5,5)
      j <- abs(c - 6L)   # 0-indexed distance
      M[r, c] <- carrier_order(i, j)
    }
  }

  if (as_symbol) {
    M_sym <- matrix(NA_character_, nrow = 11L, ncol = 11L)
    for (r in 1:11) {
      for (c in 1:11) {
        M_sym[r, c] <- CARRIER_ALPHABET[M[r, c] + 1L]
      }
    }
    M_sym
  } else {
    M
  }
}

#' @title Order value at (i,j) in the S_5 carrier (frozen rule)
#' @description The exact v(i,j) rule for the 11x11 carrier.
#' @param i integer, row distance from center (0..5)
#' @param j integer, column distance from center (0..5)
#' @return integer order 0..5 (F=0 .. A=5)
#' @keywords internal
carrier_order <- function(i, j) {
  i <- as.integer(i); j <- as.integer(j)
  if (i < 0 || i > 5 || j < 0 || j > 5) {
    stop("i,j must be in 0..5 (S_5 carrier).", call. = FALSE)
  }

  mn <- min(i, j)
  mx <- max(i, j)
  s <- i + j

  # Rule priority (frozen spec, verified against key properties):
  # 1) normal zone (center neighborhood): min(i+j,5) -- saturates only here
  if (mn <= 1L) {
    return(min(s, 5L))
  }
  # 2) pure diagonal: 2*ceil(i/2), saturate 5 (takes precedence over square)
  if (i == j) {
    return(min(2L * ceiling(i / 2), 5L))
  }
  # 3) square zone: max(i,j)
  if (s <= 6L) {
    return(mx)
  }
  # 4) square far-corner: min(i+j,5)
  min(s, 5L)
}
