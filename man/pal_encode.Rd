\name{pal_encode}
\alias{pal_encode}
\title{Encode visualr_pal to palindrome grammar text}
\usage{
pal_encode(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  Single character, the palindrome text.
}
\description{
  Inverse of \code{pal_parse}: build the frozen palindrome storage form
  \code{{A{B{C{D{e}D}C}B}A}} from a \code{visualr_pal}. Bijective:
  \code{pal_parse(pal_encode(S)) == S} and
  \code{pal_encode(pal_parse(text)) == text} for canonical text.
  Interoperability layer with \code{mapping_pack.py encode_palindrome}.
}
\examples{
pal_encode(new_pal_state(c("A", "B", "C", "D"), "e"))
}
