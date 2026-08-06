\name{peel}
\alias{peel}
\title{Peel chain: S_n to S_n-minus-1}
\usage{
peel(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A new \code{visualr_pal} with one fewer shell.
}
\description{
  Strip one order from a pal state: the innermost shell becomes the new
  core (center-block fusion). Chain: S_4 -> S_3 -> S_2 -> S_1 -> S_0.
}
\examples{
peel(new_pal_state(c("A","B","C","D"), "e"))
}
