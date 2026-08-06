\name{pal_parse}
\alias{pal_parse}
\title{Parse palindrome grammar to visualr_pal}
\usage{
pal_parse(text, mapping_pack_id = DEFAULT_MAPPING_PACK_ID, provenance = list())
}
\arguments{
  \item{text}{Single character, palindrome text like
    \code{"{A{B{C{D{e}D}C}B}A}"}.}
  \item{mapping_pack_id}{Optional override, defaults to
    \code{"pal-jiugong-v0.1"}.}
  \item{provenance}{Optional list.}
}
\value{
  A \code{visualr_pal} object.
}
\description{
  Parse the frozen palindrome storage form \code{{A{B{C{D{e}D}C}B}A}}
  into a \code{visualr_pal}. The bracket-nested grammar is uniquely
  parseable (prefix matching), so parsing is the bijective inverse of
  \code{pal_encode}. Interoperability layer with the Python reference
  implementation (mapping_pack.py \code{parse_palindrome}).
}
\examples{
pal_parse("{A{B{C{D{e}D}C}B}A}")
pal_parse("{A{B}A}")
}
