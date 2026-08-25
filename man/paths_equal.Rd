\name{paths_equal}
\alias{paths_equal}
\title{Full-history equality of two TransmissionPaths}
\usage{
paths_equal(p1, p2)
}
\arguments{
  \item{p1}{A \code{visualr_transmission_path}.}
  \item{p2}{A \code{visualr_transmission_path}.}
}
\value{
  A logical: TRUE only if \code{p1} and \code{p2} share the identical full
  position sequence and the identical full step sequence.
}
\description{
  \code{paths_equal} compares two paths by their entire history — both the
  positions and the steps must be \code{identical}. Two paths that reach the
  same endpoint by different routes compare unequal, which is the future
  promotion gate \emph{same endpoint, different path is not the same state}.
}
\details{
  This is intentionally stronger than endpoint equality: a Merge's state is
  identified by how it got there as well as where it is. The name signals
  that an equal \code{\link{transmission_signature}} does NOT imply equal
  paths, let alone equal transport results.
}
\examples{
shared <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
paths_equal(new_transmission_path("m1", shared),
            new_transmission_path("m2", shared))
}