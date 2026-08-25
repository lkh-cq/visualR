\name{new_position_state}
\alias{new_position_state}
\title{Construct a PositionState (base-space point p)}
\usage{
new_position_state(address, coordinate, cell, layer = 0L, chart = "grid")
}
\arguments{
  \item{address}{Character vector (non-empty, non-NA). Base-space address;
    distinct address implies distinct entity (A6).}
  \item{coordinate}{Numeric vector, one value per address element.}
  \item{cell}{Single non-empty character. Addressable cell owning the point.}
  \item{layer}{Single non-negative integer; default 0L.}
  \item{chart}{Single non-empty character; default \code{"grid"}. The chart
    (coordinate system) the coordinate is expressed in.}
}
\value{
  Object of class \code{visualr_position_state}.
}
\description{
  \code{new_position_state} is the first-class carrier for the base-space
  point p that v0.7 already treated as state (A6). It bundles an
  \code{address}, a numeric \code{coordinate}, an owning \code{cell}, a
  \code{layer} and a \code{chart}. Construction is strictly validated and
  fails closed on malformed input.
}
\details{
  PositionState is a plain, value-like list (no private env). Address and
  coordinate lengths must match; layer must be an integer >= 0; cell and
  chart must be single non-empty characters. The object is structurally
  comparable with \code{identical}, which \code{\link{paths_equal}} and the
  adjacency predicate rely on.
}
\examples{
p <- new_position_state(c("/alpha", "/alphab"), c(0, 1), "grid", layer = 0L)
p$coordinate
}