\name{interact}
\alias{interact}
\title{Full interaction loop: new state -> jiugong -> meta-operator}
\usage{
interact(x, op = "identity")
}
\arguments{
  \item{x}{A \code{visualr_pal} or grammar string.}
  \item{op}{Single character, operator name.}
}
\value{
  \code{visualr_pal}: the fold-back result (storage-ready) if the
  computed state is closed; otherwise the original pal unchanged.
}
\description{
  The complete fold-back closure: compute a new interaction state from
  a pal, render it as jiugong, and fold it back to a storage-ready
  meta-operator state. Demonstrates the whole "storage -> compute ->
  fold-back" loop in one command.
}
\examples{
interact("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
}
