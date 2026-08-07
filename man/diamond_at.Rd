\name{diamond_at}
\alias{diamond_at}
\title{Lazy order lookup at (x,y) — no field materialization}
\usage{
diamond_at(pal, x, y)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
  \item{x}{Integer, column offset from center (0 = center).}
  \item{y}{Integer, row offset from center (0 = center).}
}
\value{
  Integer order (0..n), or NA if outside the diamond (|x|+|y| > n).
}
\description{
  Compute the order lambda = n - |x| - |y| at a single point without
  building the full (2n+1)^2 matrix. CPU-first: the field need never
  be materialized.
}
\examples{
diamond_at(new_pal_state(c("A","B","C","D"), "e"), 0, 0)
}
