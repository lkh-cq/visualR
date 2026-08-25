\name{merge_position}
\alias{merge_position}
\title{Read the PositionState of a Merge}
\usage{
merge_position(m)
}
\arguments{
  \item{m}{A \code{visualr_merge}.}
}
\value{
  A \code{visualr_position_state}. If the merge carries one, it is returned
  as-is; otherwise a legacy \code{address} is projected into a synthetic
  PositionState.
}
\description{
  \code{merge_position} is the single reader of a Merge's position. It
  returns the attached \code{position_state} when present, and otherwise
  projects a legacy scalar \code{address} into a PositionState so that
  v0.8 geometric code can consume older merges.
}
\details{
  The legacy projection uses \code{new_position_state(m$address,
  seq_along(m$address), "legacy")}: a unit lattice coordinate and the
  \code{"legacy"} chart, which marks coordinates as a compatibility
  sequence rather than a real metric coordinate. A merge with neither
  \code{position_state} nor \code{address} stops.
}
\examples{
m <- new_merge("payload", "m1", "local-A", 1L)
m$address <- c("/a", "/b")
merge_position(m)$address
}