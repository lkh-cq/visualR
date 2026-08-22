\name{register_harmony_operator}
\alias{register_harmony_operator}
\alias{harmony_step}
\alias{harmony_builtin_names}
\alias{harmony_seed_builtins}
\title{v0.7.0 Phase 5: Harmony ABI (interface, not theory)}
\description{
The \code{H} interface. \code{harmony_step()} takes a
\code{visualr_adjacency_pair} (the only legal input, A3) and produces a
\code{HarmonyEvent} carrying a fresh \code{Merge}. Operators transform only
CONTENT; they never read Router state or an envelope. Built-in toy baselines:
identity, swap, pair_comp, reversible_toy. The interaction is deterministic
(merge_id is a pure function of the pair) so serial and parallel execution
agree (gate 14.4). Never a counter.
}
\usage{
register_harmony_operator(name, fn, overwrite = FALSE)
harmony_step(pair, operator = "identity")
harmony_builtin_names()
harmony_seed_builtins(overwrite = FALSE)
}
\arguments{
\item{name}{single non-empty operator name.}
\item{fn}{function \code{fn(merge_a_content, merge_b_content, pair)} returning
new (non-NULL) content.}
\item{overwrite}{logical; allow replacing a built-in (default FALSE, fail
closed).}
\item{pair}{a \code{visualr_adjacency_pair}.}
\item{operator}{single non-empty operator name.}
}
\value{
\code{harmony_step} returns a \code{visualr_harmony_event} whose \code{result}
is the new \code{Merge} (M_ij'). \code{register_harmony_operator} returns
\code{invisible(NULL)}.
}
\seealso{
\code{\link{router_contract}}, \code{\link{materialize_adjacency}},
\code{\link{run_emergence_round}}
}
