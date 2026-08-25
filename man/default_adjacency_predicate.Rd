\name{default_adjacency_predicate}
\alias{default_adjacency_predicate}
\title{Geometric adjacency predicate over two positions}
\usage{
default_adjacency_predicate(max_distance = 1, metric_name = "manhattan",
                            same_layer_only = TRUE)
}
\arguments{
  \item{max_distance}{Single non-negative number; the C_distance cutoff.}
  \item{metric_name}{Registered MetricLaw name used for C_distance.}
  \item{same_layer_only}{Logical; require identical layer (C_layer).}
}
\value{
  A predicate function \code{function(pi_, pj_, logical_time)} returning a
  logical.
}
\description{
  \code{default_adjacency_predicate} builds the geometric predicate
  \code{A_t(i,j) = 1[C_space AND C_distance AND C_distinct]} that decides
  whether two positions are adjacent. It is independent of any Router plan;
  only positions that pass it become AdjacencyPair candidates.
}
\details{
  The predicate is semantically blind: it reads ONLY positions
  (addresses, coordinates, cell, layer, chart) and never merges content (A2).
  It applies C_distinct (different address), C_layer (same layer when
  \code{same_layer_only}), C_space (same chart — a chart change needs an
  explicit transition contract) and C_distance under the registered metric.
  The returned closure fetches the metric at call time, so the metric must be
  registered before the predicate is first used.
}
\examples{
register_metric("manhattan", function(a, b) sum(abs(a$coordinate - b$coordinate)))
p0 <- new_position_state("/a", c(0,0), "grid")
p1 <- new_position_state("/b", c(1,0), "grid")
pred <- default_adjacency_predicate(1, "manhattan")
pred(p0, p1, 1L)
}