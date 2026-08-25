\name{field_gradient}
\alias{field_gradient}
\alias{print.visualr_field_gradient}
\title{Address-aware numeric field gradients}
\usage{
field_gradient(
  field,
  chart = NULL,
  spacing = NULL,
  masked_policy = "refuse"
)

\method{print}{visualr_field_gradient}(x, ...)
}
\arguments{
\item{field}{A real-valued \code{visualr_numeric_field}.}
\item{chart}{Optional matching \code{visualr_polar_chart}.}
\item{spacing}{One positive coordinate step for a path, or
two positive values in row/column order for a carrier. Named values
must use \code{address}, or \code{row} and \code{col}, respectively.
Defaults to one.}
\item{masked_policy}{Explicit masked-neighbour policy. Only
\code{"refuse"} is implemented in v0.6.2.}
\item{x}{A \code{visualr_field_gradient}.}
\item{...}{Unused.}
}
\value{A \code{visualr_field_gradient}.}
\description{
Computes finite differences without hidden padding, periodic
continuation, or address inference. Carrier fields use unit spacing,
unless another spacing is declared, central interior differences, and
one-sided observed-boundary
differences. Path fields use forward slopes over increasing global PAL
addresses scaled by the declared address step. Fields must be fully
observed under the explicit \code{"refuse"} masked policy; no imputation
is inferred.
}
\details{
When a matching polar chart is provided, radial and tangential
components are projections of the row/column gradient at the existing
addresses. The center angle remains undefined and no samples are
interpolated.
}
\examples{
field <- new_numeric_field(
  matrix(1:9, 3L), value_semantics = "fixture",
  boundary_state = "closed"
)
field_gradient(
  field,
  polar_chart(field),
  spacing = c(row = 0.5, col = 2)
)
}
