\name{pal_to_jiugong}
\alias{pal_to_jiugong}
\title{Map visualr_pal to Jiugong Grid}
\description{
  Maps a \code{visualr_pal} object to a k-by-k jiugong grid matrix by
  filling the unfolded palindrome in row-major order. Only works when
  the unfolded length (2 * length(shells) + 1) is a perfect square.
}
\usage{
pal_to_jiugong(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A \code{visualr_jiugong} S3 object with fields: \code{grid} (character matrix),
  \code{mapping_pack_id} (character scalar).
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
jg <- pal_to_jiugong(S4)
print(jg$grid)
}
