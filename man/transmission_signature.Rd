\name{transmission_signature}
\alias{transmission_signature}
\title{Lossy digest of a TransmissionPath}
\usage{
transmission_signature(path)
}
\arguments{
  \item{path}{A \code{visualr_transmission_path}.}
}
\value{
  A list with \code{merge_id}, \code{n_steps}, \code{grade_counts} (a
  factor-famed table over T1-T4) and \code{t_start}/\code{t_end} logical
  times (NA when the path has no steps).
}
\description{
  \code{transmission_signature} collapses a path into a compact audit
  digest: step count, grade histogram and first/last logical time. It is a
  lossy summary intended for audit and reporting only.
}
\details{
  Contract caveat (holonomy warning): an equal signature does NOT imply equal
  transport results. Two paths of the same length, grades and time span can
  still differ in which positions were traversed, so a signature should never
  be used to compare transport outcomes — only \code{\link{paths_equal}} on
  full history does that.
}
\examples{
p0 <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
path <- new_transmission_path("m1", p0)
transmission_signature(path)$n_steps
}