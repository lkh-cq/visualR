\name{route_emergence}
\alias{route_emergence}
\alias{new_router_policy}
\alias{get_router_policy}
\alias{register_baseline_router_policies}
\alias{identity_route}
\alias{nearest_valid_route}
\alias{phase_route}
\alias{resource_route}
\alias{deterministic_shuffle_route}
\alias{random_reference_route}
\title{v0.7.0 Phase 2/3: Central Router ABI and baseline policies}
\description{
Central Router entry point and plugin policy registry. The Router reads ONLY
routing envelopes plus structural snapshot fields (semantic blindness, A2);
it never reads a Merge payload. Its output is a \code{RoutingPlan} that
carries no semantic score / prediction / new Merge (A4). The baseline policies
are toy policies whose purpose is to confirm the ABI holds when swapped.
}
\usage{
route_emergence(packets, snapshot, policy = "identity_route")
new_router_policy(name, fn, overwrite = FALSE)
get_router_policy(name)
register_baseline_router_policies(overwrite = TRUE)
identity_route(envelopes, snapshot)
nearest_valid_route(envelopes, snapshot)
phase_route(envelopes, snapshot)
resource_route(envelopes, snapshot)
deterministic_shuffle_route(envelopes, snapshot)
random_reference_route(envelopes, snapshot)
}
\arguments{
\item{packets}{list of \code{visualr_emergence_packet}.}
\item{snapshot}{a \code{visualr_router_snapshot} (A5: frozen per round).}
\item{policy}{single non-empty policy name.}
\item{name}{single non-empty policy name.}
\item{fn}{function \code{fn(envelopes, snapshot)} returning a list with
placements, adjacencies (list of edges each
\code{list(source_packet_id=, dest_packet_id=)}), and optionally
policy_evidence.}
\item{overwrite}{logical; allow replacing an existing policy.}
\item{envelopes}{list of \code{visualr_routing_envelope}.}
}
\value{
\code{route_emergence} returns a validated \code{visualr_routing_plan}.
\code{register_baseline_router_policies} returns \code{invisible(NULL)}.
Policy functions return the policy result list.
}
\seealso{
\code{\link{router_contract}}, \code{\link{materialize_adjacency}},
\code{\link{run_emergence_round}}
}
