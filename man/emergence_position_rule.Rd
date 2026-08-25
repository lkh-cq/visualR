\name{emergence_position_rule}
\alias{emergence_position_rule}
\title{Emergence position rule (reference policies)}
\usage{
emergence_position_rule(policy, left_pos, right_pos)
}
\arguments{
  \item{policy}{Single character, one of \code{left_origin},
    \code{right_origin} or \code{shared_boundary}.}
  \item{left_pos}{A \code{visualr_position_state}.}
  \item{right_pos}{A \code{visualr_position_state}.}
}
\value{
  A \code{visualr_position_state} ranked by the chosen policy.
}
\description{
  \code{emergence_position_rule} is an explicit, still-unresolved interface
  for the position a freshly emerged Merge should take. It provides three
  reference policies and fails closed on any other name
  (left/right-origin/shared-boundary).
}
\details{
  \code{left_origin} and \code{right_origin} return the respective input
  position; \code{shared_boundary} builds a new PositionState at the midpoint
  of the two coordinates, a joint address/cell label, and the left layer and
  chart. Experiments decide later which policy is authoritative; the gateway
  is kept explicit so the choice is never implicit.
}
\examples{
p1 <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
p2 <- new_position_state(c("/b", "/bb"), c(2,0), "grid")
emergence_position_rule("shared_boundary", p1, p2)$coordinate
}