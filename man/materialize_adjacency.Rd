\name{materialize_adjacency}
\alias{materialize_adjacency}
\alias{validate_adjacency}
\title{v0.7.0 Phase 4: Adjacency Materialization}
\description{
Converts a \code{RoutingPlan}'s proposed edges into \code{AdjacencyPair}
objects — the ONLY legal Harmony input (A3: no adjacency, no computation).
Reads only structural plan/snapshot fields (semantic blindness, A2); fails
closed on malformed edges, self-adjacency (A6) or non-existent packets.
}
\usage{
materialize_adjacency(plan, snapshot, logical_time)
validate_adjacency(plan)
}
\arguments{
\item{plan}{a \code{visualr_routing_plan}.}
\item{snapshot}{a \code{visualr_router_snapshot} (provides boundaries/space).}
\item{logical_time}{single integer round tag.}
}
\value{
\code{materialize_adjacency} returns a list of \code{visualr_adjacency_pair}.
\code{validate_adjacency} returns \code{TRUE} (or stops fail-closed).
}
\seealso{
\code{\link{router_contract}}, \code{\link{harmony_step}},
\code{\link{run_emergence_round}}
}
