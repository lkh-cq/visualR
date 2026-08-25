\name{transmit_step}
\alias{transmit_step}
\title{Transmit a Merge one step under a metric and transport law}
\usage{
transmit_step(merge_obj, from, to, metric_name, transport_law_name,
              logical_time, regulation = NULL)
}
\arguments{
  \item{merge_obj}{A \code{visualr_merge} to transport.}
  \item{from}{A \code{visualr_position_state} origin.}
  \item{to}{A \code{visualr_position_state} destination.}
  \item{metric_name}{Registered MetricLaw name (see
    \code{\link{get_metric}}).}
  \item{transport_law_name}{Registered TransportLaw name (see
    \code{\link{get_transport_law}}).}
  \item{logical_time}{Single non-negative integer round tag.}
  \item{regulation}{Optional regulation annotation, default NULL.}
}
\value{
  A \code{visualr_transported_state} carrying the merge at the transported
  position, its extended immutable path and its audit signature.
}
\description{
  \code{transmit_step} moves a positioned Merge one hop along an immutable
  path under a metric (how far) plus a transport law (how the position maps).
  It extends the path by a T1 step, records the distance, and applies the
  transport law to the \emph{position} — never to the payload.
}
\details{
  The metric must return a single non-negative finite distance and the
  transport law must return a non-NULL \code{$position}; both fail closed.
  The result is a new TransportedState; the merge's opaque content is left
  untouched, and the transport does not mint a new Merge identity.
}
\examples{
register_metric("manhattan", function(a, b) sum(abs(a$coordinate - b$coordinate)))
register_transport_law("grid_identity", function(state, from, to, regulation = NULL) state)
m <- new_merge("payload", "m1", "local-A", 1L)
p0 <- new_position_state("/a", c(0,0), "grid")
p1 <- new_position_state("/b", c(1,0), "grid")
transmit_step(m, p0, p1, "manhattan", "grid_identity", 1L)$position$address
}