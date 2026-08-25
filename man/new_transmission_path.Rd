\name{new_transmission_path}
\alias{new_transmission_path}
\title{Construct an immutable TransmissionPath}
\usage{
new_transmission_path(merge_id, start_position)
}
\arguments{
  \item{merge_id}{Single character. Identity of the merge traversing the
    path.}
  \item{start_position}{A \code{visualr_position_state}: the path origin.}
}
\value{
  Object of class \code{visualr_transmission_path}, carrying
  \code{merge_id}, a \code{positions} list and an empty \code{steps} list.
}
\description{
  \code{new_transmission_path} opens an append-only, immutable history for a
  merge: a sequence of PositionStates plus a sequence of graded steps
  recorded between them. There is deliberately no mutation API.
}
\details{
  The path is the record \code{gamma = (p_0, ..., p_k)} that participates in
  transport results. Because it is append-only, a step can only be added when
  its \code{from} equals the current head position
  (\code{\link{append_transmission_step}} enforces this, fail closed).
}
\examples{
p0 <- new_position_state(c("/a", "/ab"), c(0, 0), "grid")
path <- new_transmission_path("m1", p0)
path$positions[[1]]$address
}