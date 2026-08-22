\name{run_emergence_round}
\alias{run_emergence_round}
\alias{run_emergence_system}
\alias{print.visualr_emergence_system}
\title{v0.7.0 Phase 6/7: Emergence Round orchestrator and multi-round loop}
\description{
\code{run_emergence_round} wires Phases 1-5 into one atomic
\code{visualr_computation_round}: pack -> freeze snapshot (A5) -> route ->
adjacency -> harmony -> commit. It resolves the packet_id<->Merge seam so
Harmony receives real Merge objects. \code{run_emergence_system} runs several
rounds and reports STRUCTURAL topology observability (no intelligence score).
}
\usage{
run_emergence_round(packets, local_state, space, resources, boundaries,
                    logical_time, policy = "identity_route",
                    harmony_operator = "identity", historical = list())
run_emergence_system(initial_merges, rounds = 3L, space, resources,
                     boundaries, policy = "identity_route",
                     harmony_operator = "identity")

\method{print}{visualr_emergence_system}(x, ...)
}
\arguments{
\item{packets}{list of \code{visualr_emergence_packet}.}
\item{local_state}{list of \code{visualr_merge} (the current locals).}
\item{space}{character vector of addressable cells.}
\item{resources}{named numeric per-cell residual capacity.}
\item{boundaries}{named character, \code{"open"}/\code{"closed"} per cell.}
\item{logical_time}{single integer round tag.}
\item{policy}{routing policy name (see \code{\link{route_emergence}}).}
\item{harmony_operator}{harmony operator name (see
\code{\link{register_harmony_operator}}).}
\item{historical}{list of allowed structural history (A5).}
\item{initial_merges}{list of \code{visualr_merge} for round 1.}
\item{rounds}{integer >= 1, number of rounds.}
\item{x}{a \code{visualr_emergence_system}.}
\item{...}{unused.}
}
\value{
\code{run_emergence_round} returns a \code{visualr_computation_round}.
\code{run_emergence_system} returns a \code{visualr_emergence_system} whose
\code{observability} holds structural facts only.
}
\seealso{
\code{\link{router_contract}}, \code{\link{route_emergence}},
\code{\link{materialize_adjacency}}, \code{\link{register_harmony_operator}}
}
