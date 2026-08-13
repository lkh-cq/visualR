\name{carrier_adapter}
\alias{carrier_adapter}
\alias{print.visualr_carrier_adapter}
\title{Carrier transfer adapter with typed-view discipline}
\usage{
carrier_adapter(x, from_width, to_width)

\method{print}{visualr_carrier_adapter}(x, ...)
}
\arguments{
\item{x}{numeric or character square matrix.}

\item{from_width}{integer(1), current carrier width.}

\item{to_width}{integer(1), target carrier width.}

\item{...}{unused.}
}
\value{
A list of class \code{visualr_carrier_adapter} with adapted matrix,
from_width, to_width, rule and matched. Fail-closed: illegal widths
or illegal transfers stop with an error.
}
\description{
Transfers a square matrix between carrier widths with explicit,
auditable rules, mirroring TCN's downsample discipline: same width is
identity pass-through; different width requires an explicit
adaptation. Legal widths are 3 (compute path), 4 (evidence view) and
11 (S_5 carrier view). 3x3 -> 11x11 is refused: the S_5 carrier must
be built by \code{carrier_11x11()}, not by padding (typed view
discipline).
}
\examples{
carrier_adapter(matrix(1:9, 3L, 3L), 3L, 4L)
carrier_adapter(matrix(1:9, 3L, 3L), 3L, 3L)$matched  # TRUE
}
