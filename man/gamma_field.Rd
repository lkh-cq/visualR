\name{gamma_field}
\alias{gamma_field}
\title{Gamma generator: S_k to meta-jiugong K_k}
\usage{
gamma_field(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A 3x3 character matrix (K_k).
}
\description{
  Build the 3x3 meta-jiugong (local density field neighborhood) from a
  pal state. Cross cells drop 1 order, diagonal cells drop 2 orders
  (frozen Gamma rule). Center cell is the lowercased core — the stripped
  marker (local center, NOT the globally isotropic singularity; only the
  global center keeps its case). Validated against all 4 frozen spec
  examples. NOTE: this is the FIRST executable realization of the spec
  (Python reference has not yet implemented Gamma).
}
\examples{
gamma_field(new_pal_state(c("A","B","C","D"), "e"))
}
