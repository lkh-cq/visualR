\name{format_pal}
\alias{format_pal}
\title{Serialize a visualr_pal to String}
\description{
  Serializes a \code{visualr_pal} object into a single character string
  using a line-based format with deparse encoding for shells and provenance.
}
\usage{
format_pal(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A single character string.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
format_pal(S4)
}
