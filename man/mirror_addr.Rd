\name{mirror_addr}
\alias{mirror_addr}
\title{Central inversion (mirror address)}
\usage{
mirror_addr(row, col)
}
\arguments{
  \item{row}{Integer row coordinate (1..3).}
  \item{col}{Integer column coordinate (1..3).}
}
\value{
  Integer vector of length 2: \code{c(new_row, new_col)}.
}
\description{
  Frozen central inversion \code{Sigma}: \code{(r,c) -> (4-r, 4-c)} in
  1-indexed 3x3 jiugong coordinates. The center (2,2) is a fixed point.
  Invariant: \code{Sigma^2 = I}.
}
\examples{
mirror_addr(1L, 1L)  # c(3, 3)
mirror_addr(2L, 2L)  # c(2, 2)
}
