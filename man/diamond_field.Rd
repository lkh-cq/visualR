\name{diamond_field}
\alias{diamond_field}
\title{Compute Diamond Order Field}
\description{
  Computes the diamond order field for a \code{visualr_pal} object.
  The order at each cell is \code{lambda(p) = n - |p - c|_1} where n is
  the number of shells, c is the center, and |.|_1 is Manhattan distance.
  Cells outside the diamond are NA. This is a one-way projection:
  no inverse function exists.
}
\usage{
diamond_field(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A \code{visualr_diamond} S3 object with fields: \code{matrix} (numeric matrix),
  \code{center} (integer vector of length 2), \code{radius} (integer),
  \code{n} (integer).
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
dm <- diamond_field(S4)
print(dm$matrix[5, 5])  # 4 (center order = n)
}
