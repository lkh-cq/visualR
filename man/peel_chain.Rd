\name{peel_chain}
\alias{peel_chain}
\title{Full peel chain}
\usage{
peel_chain(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  List of \code{visualr_pal} objects, longest first (S_n ... S_0).
}
\description{
  Peel down to S_0, returning the whole chain.
}
\examples{
peel_chain(new_pal_state(c("A","B","C","D"), "e"))
}
