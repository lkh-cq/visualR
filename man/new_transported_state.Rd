\name{new_transported_state}
\alias{new_transported_state}
\title{Construct a TransportedState}
\usage{
new_transported_state(merge_obj, position, path, signature,
                      regulation_trace = list())
}
\arguments{
  \item{merge_obj}{A \code{visualr_merge} being transported.}
  \item{position}{A \code{visualr_position_state} of the state after
    transport.}
  \item{path}{A \code{visualr_transmission_path} recording the history.}
  \item{signature}{A list; normally the path's
    \code{\link{transmission_signature}}.}
  \item{regulation_trace}{Optional list of regulation annotations.}
}
\value{
  Object of class \code{visualr_transported_state}.
}
\description{
  \code{new_transported_state} bundles a merge with its current position,
  its immutable path, an audit signature and a regulation trace. It is the
  unit of state the geometric runtime advances around the round.
}
\details{
  Transport does NOT create a new Merge identity — the transported state
  reuses its merge object as-is, so \code{merge_id} is preserved across
  steps. Only Harmony creates fresh Merges. The merge's opaque payload is
  never mutated by transport; regulation may only annotate the trace.
}
\examples{
m <- new_merge("payload", "m1", "local-A", 1L)
p0 <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
path <- new_transmission_path("m1", p0)
st <- new_transported_state(m, p0, path, transmission_signature(path))
st$merge_id
}