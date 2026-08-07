\name{pal_to_square_view}
\alias{pal_to_square_view}
\title{General square view: S_n -> k x k matrix (k^2 = unfolded length)}
\usage{
pal_to_square_view(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  List with fields grid (k x k matrix), mapping_pack_id.
}
\description{
  The general perfect-square projection. When the unfolded palindrome
  length is a perfect square (1, 9, 25, ...), the path can be read
  row-major into a k x k matrix. This is NOT the frozen S_4 -> 3x3
  jiugong; it is the general square view (v0.2.2 P1).
}
\examples{
pal_to_square_view(new_pal_state(c("A","B","C","D"), "e"))
}
