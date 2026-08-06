\name{locate}
\alias{locate}
\title{Locate symbol in the fourth-dimension mapping table}
\usage{
locate(sym)
}
\arguments{
  \item{sym}{Single character, one of \code{A/B/C/D/e}.}
}
\value{
  List with fields: \code{symbol}, \code{complement}, \code{head_index},
  \code{tail_index}, \code{head_addr}, \code{tail_addr}, \code{orbit},
  \code{mirror_tail_addr}.
}
\description{
  O(1) lookup of a symbol's head/tail palindrome indices and jiugong
  coordinates from the user-frozen fourth-dimension mapping table
  (sanyuan-runtime v0.2). Ported from \code{MappingPack.locate()} in the
  Python reference implementation.
}
\examples{
locate("D")
locate("e")
}
