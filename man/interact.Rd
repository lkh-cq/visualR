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
  \code{visualr_compute_result} with fields: input, carrier, computed,
  closed (logical fact), action (promote/transient/recurse/reject),
  fold_back (pal if promoted, else NULL), trace. Never silently
  discards computation (P0-6).
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
