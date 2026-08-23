\name{polar_chart}
\alias{polar_chart}
\alias{print.visualr_polar_chart}
\title{Lossless polar observation chart}
\usage{
polar_chart(field, resample = FALSE)

\method{print}{visualr_polar_chart}(x, ...)
}
\arguments{
\item{field}{A two-dimensional \code{visualr_numeric_field}.}
\item{resample}{Must be \code{FALSE}; interpolation is not implemented
without a declared sampling contract.}
\item{x}{A \code{visualr_polar_chart}.}
\item{...}{Unused.}
}
\value{A \code{visualr_polar_chart}.}
\description{
Appends exact geometric \code{r} and \code{theta} coordinates to every
existing row/column address without replacing address identity or
resampling values.
}
\details{
The positive column axis is angle zero and angles increase
counterclockwise with the row axis treated as pointing down in the
matrix and up geometrically. Odd carriers have one geometric sample at
the origin; its angle is undefined. Even carriers distinguish the
half-cell geometric center from the four topology-center addresses.
}
\examples{
field <- new_numeric_field(
  matrix(1:9, 3L), value_semantics = "fixture",
  boundary_state = "closed"
)
polar_chart(field)
}
