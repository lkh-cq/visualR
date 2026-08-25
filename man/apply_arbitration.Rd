\name{apply_arbitration}
\alias{apply_arbitration}
\title{Defer collision losers by rewinding their paths}
\usage{
apply_arbitration(states, arb)
}
\arguments{
  \item{states}{List of \code{visualr_transported_state} objects.}
  \item{arb}{Result of \code{\link{arbitrate_collisions}}.}
}
\value{
  List with \code{states} (post-deferral) and \code{deferred} indices.
}
\description{
  Losers are deferred, never deleted: each loser is rewound to its previous
  path position via an immutable prefix rebuild; a loser whose path has a
  single step defers in place. Payloads are never touched and no input
  object is mutated.
}
\examples{
\dontshow{
ps <- new_position_state(c("/a", "/ab"), c(0, 1), "grid")
m <- new_merge("x", "M2", "l2", 1L)
pth <- new_transmission_path("M2", ps)
ts <- new_transported_state(m, ps, pth, list())
out <- apply_arbitration(list(ts), list(winners = list(), losers = list()))
length(out$deferred)
}
}
