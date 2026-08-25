\name{attach_position_state}
\alias{attach_position_state}
\title{Attach a PositionState to a Merge}
\usage{
attach_position_state(m, ps)
}
\arguments{
  \item{m}{A \code{visualr_merge}.}
  \item{ps}{A \code{visualr_position_state}.}
}
\value{
  The \code{visualr_merge} \code{m}, modified in place by attaching
  \code{ps} as \code{m$position_state}. The merge \code{$address} field is
  filled from the PositionState if not already set.
}
\description{
  \code{attach_position_state} is the Merge-attachment seam for geometry:
  it binds a PositionState to a Merge without touching the frozen
  \code{\link{new_merge}} contract. The merge \code{$address} remains the
  compatibility field for legacy code.
}
\details{
  Fail-closed rule: if \code{m$address} is already set and does not agree
  with the PositionState address, the attach is refused. A conflicted merge
  and a PositionState naming a different address are never silently merged.
}
\examples{
m <- new_merge("payload", "m1", "local-A", 1L)
p <- new_position_state("/alpha", 0, "grid")
m <- attach_position_state(m, p)
m$position_state$cell
}