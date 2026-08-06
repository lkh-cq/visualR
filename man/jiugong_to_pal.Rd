\name{jiugong_to_pal}
\alias{jiugong_to_pal}
\title{Map Jiugong Grid to visualr_pal}
\description{
  Converts a \code{visualr_jiugong} grid back to a \code{visualr_pal} object
  by reading the matrix in row-major order and folding the resulting palindrome.
  Invariant: \code{jiugong_to_pal(pal_to_jiugong(S)) == S} for perfect-square states.
}
\usage{
jiugong_to_pal(jiugong,
               mapping_pack_id = NULL,
               provenance = list())
}
\arguments{
  \item{jiugong}{A \code{visualr_jiugong} object.}
  \item{mapping_pack_id}{Character scalar or NULL. If NULL, inherits from jiugong.}
  \item{provenance}{List. Provenance metadata.}
}
\value{
  A \code{visualr_pal} S3 object.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
jg <- pal_to_jiugong(S4)
pal <- jiugong_to_pal(jg)
}
