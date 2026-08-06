\name{parse_pal}
\alias{parse_pal}
\title{Parse a String to visualr_pal}
\description{
  Deserializes a character string produced by \code{format_pal} back into
  a \code{visualr_pal} object. Invariant: \code{parse_pal(format_pal(S)) == S}.
}
\usage{
parse_pal(string)
}
\arguments{
  \item{string}{A single character string in visualr_pal format.}
}
\value{
  A \code{visualr_pal} S3 object.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
parsed <- parse_pal(format_pal(S4))
}
