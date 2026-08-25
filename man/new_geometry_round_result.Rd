\name{new_geometry_round_result}
\alias{new_geometry_round_result}
\title{Construct a geometric round result}
\usage{
new_geometry_round_result(logical_time, transported, adjacency, events,
                          new_merges, dropped)
}
\arguments{
  \item{logical_time}{Single integer round tag.}
  \item{transported}{List of \code{visualr_transported_state} entering the
    round.}
  \item{adjacency}{A \code{visualr_geometry_adjacency} (see
    \code{\link{detect_adjacency}}).}
  \item{events}{List of HarmonyEvents produced this round.}
  \item{new_merges}{List of Merges minted by Harmony this round.}
  \item{dropped}{Integer count of states consumed but not yielding a fresh
    Merge.}
}
\value{
  Object of class \code{visualr_geometry_round}.
}
\description{
  \code{new_geometry_round_result} wraps the outcome of a geometric round: the
  transported states, the detected adjacency, the Harmony events and fresh
  Merges, and the dropped count. It is the return type of
  \code{\link{run_transmission_round}}.
}
\details{
  The result is a plain record. \code{transmitted} holds the states entering
  the round unchanged (transport is per-state and additive); fresh Merges
  from Harmony live in \code{new_merges}; states that collided but evolved
  into no fresh Merge are counted in \code{dropped}.
}
\examples{
adj <- detect_adjacency(list(), function(...) FALSE, 1L)
new_geometry_round_result(1L, list(), adj, list(), list(), 0L)
}