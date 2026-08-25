\name{run_transmission_round_arbitrated}
\alias{run_transmission_round_arbitrated}
\title{Run a geometric round with collision arbitration}
\usage{
run_transmission_round_arbitrated(states, predicate, metric_name,
                                  transport_law_name, logical_time,
                                  harmony_operator = "identity")
}
\arguments{
  \item{states}{Non-empty list of \code{visualr_transported_state}.}
  \item{predicate}{An adjacency predicate function.}
  \item{metric_name}{Registered MetricLaw name.}
  \item{transport_law_name}{Registered TransportLaw name.}
  \item{logical_time}{Single non-negative integer round tag.}
  \item{harmony_operator}{Harmony operator name; default \code{"identity"}.}
}
\value{
  A \code{visualr_geometry_round} from the deconflicted states.
}
\description{
  \code{run_transmission_round_arbitrated} is the arbitration-aware wrapper
  of the geometric round. Before Geometric Adjacency and Harmony, it runs
  \code{\link{detect_cell_collisions}},
  \code{\link{arbitrate_collisions}} and \code{\link{apply_arbitration}} to
  deconflict contested cells, then delegates to
  \code{\link{run_transmission_round}} on the reconciled set. This is the
  Router-as-arbitration-plugin path.
}
\details{
  Collisions (two or more states declaring the same target cell) are arbitrated
  deterministically and semantically blind; losers are deferred (their path is
  rewound to the previous position), never deleted. If no collision is detected
  the round proceeds exactly as a plain run.
}
\examples{
register_metric("manhattan", function(a, b) sum(abs(a$coordinate - b$coordinate)))
register_transport_law("grid_identity", function(state, from, to, regulation = NULL) state)
m <- new_merge("p", "m1", "local-A", 1L)
s <- transmit_step(m, new_position_state(c("/a", "/ab"), c(0,0), "grid"),
                   new_position_state(c("/b", "/bb"), c(1,0), "grid"),
                   "manhattan", "grid_identity", 1L)
run_transmission_round_arbitrated(list(s), default_adjacency_predicate(2, "manhattan"),
                                  "manhattan", "grid_identity", 2L)$dropped
}