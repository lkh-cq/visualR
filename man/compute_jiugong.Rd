\name{compute_jiugong}
\alias{compute_jiugong}
\title{Compute emergence operator on a 3x3 matrix}
\usage{
compute_jiugong(grid, op = "identity")
}
\arguments{
  \item{grid}{A 3x3 matrix.}
  \item{op}{Single character, operator name. Built-ins: \code{"identity"},
    \code{"orbit_rotate"}. Custom operators via \code{register_operator()}.}
}
\value{
  A 3x3 matrix (the transformed working state).
}
\description{
  Apply a registered emergence operator Ω: M -> M with snapshot-commit
  transaction semantics. All components read the same snapshot, then
  write atomically. The result should be checked with
  \code{closure_jiugong()} before writing back to palindrome storage.
  Ported from \code{mapping_pack.py compute()}.
}
\examples{
compute_jiugong(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE), "identity")
}
