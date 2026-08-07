\name{carrier_11x11}
\alias{carrier_11x11}
\title{S_5 11x11 neighborhood transformation carrier}
\usage{
carrier_11x11(as_symbol = FALSE)
}
\arguments{
  \item{as_symbol}{Logical, return order SYMBOLS (F..A) instead of the
    canonical numeric orders 0..5. Default FALSE.}
}
\value{
  11x11 matrix: canonical integer orders (0..5) or, when
  \code{as_symbol=TRUE}, character symbols (F..A).
}
\description{
  Build the 11x11 carrier grid for the S_5 neighborhood transformation
  (121 cells = layer diffusion).

  SEMANTICS: the matrix is a 2D SLICE of the palindrome-dimension
  expansion. Cell value = ORDER (dimension index) 0..5 (0 at center,
  increasing outward). Letters F..A are ONLY readability placeholders
  for orders 0..5 — the numeric order is the canonical form; letters
  are a display/interop layer used to align with the frozen spec's
  alphabet.

  Frozen mixed Manhattan/Chebyshev rule: normal zone min(i+j,5);
  square zone max(i,j); pure diagonal 2*ceil(i/2); far-corner
  min(i+j,5). Verified against the frozen spec (0/121 mismatches,
  2026-08-05).
}
\examples{
carrier_11x11()
carrier_11x11(as_symbol = TRUE)
}
