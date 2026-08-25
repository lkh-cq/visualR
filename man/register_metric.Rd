\name{register_metric}
\alias{register_metric}
\alias{get_metric}
\alias{has_metric}
\title{Register and query a MetricLaw}
\usage{
register_metric(name, distance_fn)
get_metric(name)
has_metric(name)
}
\arguments{
  \item{name}{Single non-empty character. Registry key.}
  \item{distance_fn}{A function of two PositionStates, \code{function(pi, pj)}
    returning one non-negative number ("how far").}
}
\value{
  \code{register_metric} returns \code{invisible(name)}. \code{get_metric}
  returns the stored \code{distance_fn}, stopping on an unknown name.
  \code{has_metric} returns a logical.
}
\description{
  A \code{MetricLaw} answers "how far" between two positions. The three
  functions form the \code{MetricLaw} part of the v0.8 registry:
  register a metric by name, fetch it (fail closed if absent), or test that
  it exists.
}
\details{
  Distance functions receive two \code{visualr_position_state} objects and
  must return a single non-negative finite number; \code{\link{transmit_step}}
  and \code{\link{default_adjacency_predicate}} re-check this fail closed at
  call time. The built-in \code{manhattan} and \code{euclidean} reference
  metrics are registered lazily by the internal geometry defaults helper.
}
\examples{
register_metric("my_metric", function(a, b) abs(a$coordinate - b$coordinate))
has_metric("my_metric")
get_metric("my_metric")(new_position_state("/a", 0, "grid"),
                        new_position_state("/b", 3, "grid"))
}