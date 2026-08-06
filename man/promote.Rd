\name{promote}
\alias{promote}
\title{Promote: S_n-minus-1 to S_n (inverse of peel)}
\usage{
promote(pal, new_core)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
  \item{new_core}{Single character, the new center singularity.}
}
\value{
  A new \code{visualr_pal} with one more shell.
}
\description{
  Wrap the current core as the innermost shell and promote a new core
  symbol. Inverse of \code{peel} when the new core equals the original
  innermost shell's outer symbol.
}
\examples{
promote(new_pal_state(c("A","B","C"), "D"), "e")
}
