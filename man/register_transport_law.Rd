\name{register_transport_law}
\alias{register_transport_law}
\alias{get_transport_law}
\alias{has_transport_law}
\title{Register and query a TransportLaw}
\usage{
register_transport_law(name, step_fn)
get_transport_law(name)
has_transport_law(name)
}
\arguments{
  \item{name}{Single non-empty character. Registry key.}
  \item{step_fn}{A function \code{function(state, from, to, regulation =
    NULL)} describing how a state is mapped across positions; must return a
    list carrying \code{$position}.}
}
\value{
  \code{register_transport_law} returns \code{invisible(name)}.
  \code{get_transport_law} returns the stored \code{step_fn}, stopping on an
  unknown name. \code{has_transport_law} returns a logical.
}
\description{
  While a \code{MetricLaw} answers "how far", a \code{TransportLaw} answers
  "how a state's position compares/maps across positions" (\code{P_ij :
  E_i -> E_j}). The three functions manage the \code{TransportLaw} half of
  the v0.8 registry.
}
\details{
  A transport law maps a positioned state between cells without mutating its
  payload; it must return a list with a non-NULL \code{$position}
  (\code{\link{transmit_step}} enforces this, fail closed). The built-in
  \code{grid_identity} reference law is the flat baseline: it returns the
  destination position and, on flat-baseline cycles, must preserve trivial
  holonomy.
}
\examples{
register_transport_law("my_law", function(state, from, to, regulation = NULL) state)
has_transport_law("my_law")
get_transport_law("my_law")(list(position = 1), NULL, list(position = 2))
}