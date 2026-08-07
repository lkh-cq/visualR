\name{carrier_11x11}
\alias{carrier_11x11}
\title{S_5 11x11 neighborhood transformation carrier}
\usage{
carrier_11x11(as_symbol = TRUE)
}
\arguments{
  \item{as_symbol}{Logical, return order symbols (F..A) instead of
    integer orders. Default TRUE.}
}
\value{
  11x11 matrix: integer orders (0..5) or character symbols (F..A).
}
\description{
  Build the 11x11 carrier grid for the S_5 neighborhood transformation
  (121 cells = layer diffusion). Cell value is the order (F=0 at
  center, increasing outward to A=5 at edges), following the frozen
  mixed Manhattan/Chebyshev rule: normal zone min(i+j,5); square zone
  max(i,j); pure diagonal 2*ceil(i/2); far-corner min(i+j,5).
  Verified against the frozen spec (0/121 mismatches, 2026-08-05).
}
\examples{
carrier_11x11()
carrier_11x11(as_symbol = FALSE)
}
