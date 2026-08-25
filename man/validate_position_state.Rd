\name{validate_position_state}
\alias{validate_position_state}
\title{Validate a PositionState}
\usage{
validate_position_state(ps)
}
\arguments{
  \item{ps}{Object claimed to be a \code{visualr_position_state}.}
}
\value{
  \code{invisible(TRUE)} on success; stops with an error otherwise.
}
\description{
  \code{validate_position_state} type-checks a PositionState and rebuilds it
  through \code{\link{new_position_state}} (the single strict constructor),
  so every field is re-validated. It is the shared guard called by the path,
  transport, adjacency and runtime entry points.
}
\details{
  The function asserts \code{inherits(ps, "visualr_position_state")} and then
  delegates all field validation to the constructor. It returns a boolean but
  is normally called for its stopping side effect at API boundaries.
}
\examples{
p <- new_position_state("/alpha", 0, "grid")
validate_position_state(p)
}