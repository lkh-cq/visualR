\name{path_length_steps}
\alias{path_length_steps}
\title{Number of steps in a TransmissionPath}
\usage{
path_length_steps(path)
}
\arguments{
  \item{path}{A \code{visualr_transmission_path}.}
}
\value{
  An integer: the number of recorded steps (hops) in the path. A freshly
  created path returns 0 steps.
}
\description{
  \code{path_length_steps} returns how many graded hops a path has recorded.
  It is used by collision arbitration to rank states (fewer steps wins, as
  closer to origin).
}
\details{
  The step count is a length over \code{path$steps}; positions equal
  steps+1 for a non-empty path since each step links two positions.
}
\examples{
p0 <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
path <- new_transmission_path("m1", p0)
path_length_steps(path)
}