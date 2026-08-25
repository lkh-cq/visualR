\name{router_contract}
\alias{router_contract}
\alias{new_merge}
\alias{merge_content}
\alias{merge_id_of}
\alias{new_routing_envelope}
\alias{new_emergence_packet}
\alias{router_envelope}
\alias{validate_emergence_packet}
\alias{new_router_snapshot}
\alias{new_routing_plan}
\alias{validate_router_plan}
\alias{new_adjacency_pair}
\alias{validate_adjacency_pair}
\alias{new_harmony_event}
\alias{validate_harmony_event}
\alias{new_merge_result}
\alias{new_computation_round}
\alias{print.visualr_routing_envelope}
\alias{print.visualr_merge}
\alias{print.visualr_router_snapshot}
\alias{print.visualr_routing_plan}
\alias{print.visualr_adjacency_pair}
\title{v0.7.0 Router contract base: shared object constructors and validators}
\description{
Frozen shared types for the Central Router and Emergence Computation Loop.
See \file{inst/ROUTER_CONTRACT_v070.md} for the authoritative contract. This
module is the SINGLE writer of these objects; phase modules read them and never
redefine them. Merge content is opaque (A2): the router reads only
\code{router_envelope()}; semantic content is reachable only through
\code{merge_content()} (Harmony/local path).
}
\usage{
new_merge(content, merge_id, origin_local, logical_time)
merge_content(m)
merge_id_of(x)
new_routing_envelope(packet_id, source_local, source_address, logical_time,
                     boundary, transport = list(), integrity = character(0L))
new_emergence_packet(envelope, merge_obj)
router_envelope(packet)
validate_emergence_packet(packet)
new_router_snapshot(round, packets, space, resources, boundaries,
                    historical = list())
new_routing_plan(placements = list(), adjacencies = list(),
                 route_trace = character(0L), collisions = list(),
                 unresolved = character(0L), policy_evidence = list())
validate_router_plan(plan)
new_adjacency_pair(left_merge, right_merge, left_address, right_address,
                   shared_local_space, route_trace, logical_time)
validate_adjacency_pair(pair)
new_harmony_event(pair, operator_id, result, trace = character(0L))
validate_harmony_event(ev)
new_merge_result(new_merges = list(), adjacency_used = list(),
                 dropped = character(0L), resource_left = numeric(0L),
                 trace = character(0L))
new_computation_round(snapshot, plan, pairs, events, result)
}
\arguments{
\item{content}{opaque semantic content of a Merge (never read by router).}
\item{merge_id}{single non-empty character, unique.}
\item{origin_local}{single character local id.}
\item{logical_time}{single integer round tag.}
\item{m}{a \code{visualr_merge}.}
\item{x}{an object to reduce to a merge id (Merge or character).}
\item{packet_id, source_local, source_address, boundary}{envelope fields
(address is the routing handle; position is state, A6).}
\item{transport}{list of resource/traffic metadata.}
\item{integrity}{content integrity hash (tamper detection).}
\item{envelope}{a \code{visualr_routing_envelope}.}
\item{merge_obj}{a \code{visualr_merge} (opaque payload).}
\item{packet}{a \code{visualr_emergence_packet}.}
\item{round, packets, space, resources, boundaries, historical}{snapshot
fields; immutable for the round (A5).}
\item{placements, adjacencies, route_trace, collisions, unresolved,
policy_evidence}{routing-plan fields (A4: never semantic).}
\item{plan}{a \code{visualr_routing_plan}.}
\item{left_merge, right_merge, left_address, right_address,
shared_local_space}{adjacency-pair fields (A3: the only Harmony input).}
\item{pair}{a \code{visualr_adjacency_pair}.}
\item{operator_id}{harmony operator name.}
\item{result}{the new Merge produced by Harmony (M_ij').}
\item{ev}{a \code{visualr_harmony_event}.}
\item{new_merges, adjacency_used, dropped, resource_left}{round result fields.}
\item{trace}{trace string recorded on a HarmonyEvent or MergeResult.}
\item{snapshot, pairs, events}{round stages.}
}\value{
The constructed object of the corresponding class, or \code{TRUE} on validation
success. Validators \code{stop()} (fail closed) on contract violation.
}
\seealso{
\code{\link{route_emergence}}, \code{\link{materialize_adjacency}},
\code{\link{harmony_step}}, \code{\link{run_emergence_round}}
}
