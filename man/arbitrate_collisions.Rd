\name{arbitrate_collisions}
\alias{arbitrate_collisions}
\title{Deterministically resolve shared-resource cell collisions}
\usage{
arbitrate_collisions(states, collisions)
}
\arguments{
  \item{states}{List of \code{visualr_transported_state} objects.}
  \item{collisions}{Named list of index vectors as returned by
    \code{\link{detect_cell_collisions}}.}
}
\value{
  A list with \code{winners} (cell key -> winning state index) and
  \code{losers} (cell key -> deferred indices).
}
\description{
  Semantic-blind, deterministic tie-breaking for states that declare the
  same target cell: fewer accumulated path steps wins, then the
  lexicographically smaller merge id wins. The router has no
  meaning-choosing role here; arbitration only decides who enters first.
}
\examples{
p <- new_position_state(c("/a", "/ab"), c(0, 0), "grid")
m1 <- new_merge("x", "M1", "l1", 1L)
ts1 <- new_transported_state(m1, p, new_transmission_path("M1", p),
                             list())
\dontshow{# second state would collide; see detect_cell_collisions example}
}
