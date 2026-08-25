\name{run_transmission_round}
\alias{run_transmission_round}
\title{Run one geometric round (Snapshot->Transmission->Adjacency->Harmony->Commit)}
\usage{
run_transmission_round(states, predicate, metric_name, transport_law_name,
                       logical_time, harmony_operator = "identity",
                       arbitration = NULL)
}
\arguments{
  \item{states}{Non-empty list of \code{visualr_transported_state} entering
    the round.}
  \item{predicate}{An adjacency predicate function (see
    \code{\link{default_adjacency_predicate}}).}
  \item{metric_name}{Registered MetricLaw name.}
  \item{transport_law_name}{Registered TransportLaw name.}
  \item{logical_time}{Single non-negative integer round tag.}
  \item{harmony_operator}{Harmony operator name (see
    \code{\link{register_harmony_operator}}); default \code{"identity"}.}
  \item{arbitration}{Optional; reserved for the shared-resource collision
    plugin. Default NULL. Should drain at least one state; yields progress.}
}
\value{
  A \code{visualr_geometry_round} (see
  \code{\link{new_geometry_round_result}}).
}
\description{
  \code{run_transmission_round} wires the geometric pipeline
  \emph{Snapshot -> Transmission -> Adjacency -> Harmony -> Commit} into one
  atomic round. Each state advances one T1 step, geometric adjacency is
  detected, predicate-passing pairs meet under Harmony, and fresh Merges are
  committed. The Router is NOT in the default path; it exists only as an
  optional arbitration plugin.
}
\details{
  Transmission is per-state and additive — each state advances along its own
  history with no central repositioner and no round-robin; surviving
  positions come from \code{\link{emergence_position_rule}}. Only pairs
  passing the geometric predicate reach Harmony, and only Harmony mints fresh
  Merges. States consumed but yielding no fresh Merge are counted as dropped.
}
\examples{
register_metric("manhattan", function(a, b) sum(abs(a$coordinate - b$coordinate)))
register_transport_law("grid_identity", function(state, from, to, regulation = NULL) state)
m <- new_merge("p", "m1", "local-A", 1L)
s <- transmit_step(m, new_position_state("/a", c(0,0), "grid"),
                   new_position_state("/b", c(1,0), "grid"),
                   "manhattan", "grid_identity", 1L)
run_transmission_round(list(s), default_adjacency_predicate(2, "manhattan"),
                       "manhattan", "grid_identity", 2L)$dropped
}