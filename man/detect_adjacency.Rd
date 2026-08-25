\name{detect_adjacency}
\alias{detect_adjacency}
\title{Detect geometric adjacency pairs over a state list}
\usage{
detect_adjacency(states, predicate, logical_time)
}
\arguments{
  \item{states}{A list of \code{visualr_transported_state} or
    \code{visualr_position_state} objects.}
  \item{predicate}{An adjacency predicate function
    \code{function(pi_, pj_, logical_time)} (see
    \code{\link{default_adjacency_predicate}}).}
  \item{logical_time}{Single integer round tag.}
}
\value{
  An object of class \code{visualr_geometry_adjacency} with \code{pairs} (the
  index pairs passing the predicate), \code{n_states} and \code{logical_time}.
}
\description{
  \code{detect_adjacency} evaluates a geometric predicate over every pair of
  states (using each state's current position) and collects the passing pairs
  as the adjacency output for the current tick. Only these pairs are legal
  Harmony candidates.
}
\details{
  For a \code{visualr_transported_state} the current position is its
  \code{$position}; plain PositionStates are used directly. All positions are
  validated first. The pair carries \code{left_index}/\code{right_index},
  both positions and the logical time. This is pure geometric adjacency —
  it is independent of, not derived from, any Router plan.
}
\examples{
p0 <- new_position_state("/a", c(0,0), "grid")
p1 <- new_position_state("/b", c(1,0), "grid")
register_metric("manhattan", function(a, b) sum(abs(a$coordinate - b$coordinate)))
adj <- detect_adjacency(list(p0, p1), default_adjacency_predicate(2, "manhattan"), 1L)
length(adj$pairs)
}