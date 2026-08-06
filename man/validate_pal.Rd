\name{validate_pal}
\alias{validate_pal}
\title{Validate a visualr_pal Object}
\description{
  Checks the structure and types of a \code{visualr_pal} object.
  Returns \code{invisible(TRUE)} if valid, otherwise throws an error.
  Does NOT check active_singularities, phase, or rho+theta consistency
  (deferred to v0.2).
}
\usage{
validate_pal(pal)
}
\arguments{
  \item{pal}{An object to validate.}
}
\value{
  \code{invisible(TRUE)} if valid. Throws an error otherwise.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
validate_pal(S4)
}
