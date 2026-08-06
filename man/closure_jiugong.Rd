\name{closure_jiugong}
\alias{closure_jiugong}
\title{Closure gate for a 3x3 jiugong matrix}
\usage{
closure_jiugong(grid)
}
\arguments{
  \item{grid}{A 3x3 matrix (character or atomic).}
}
\value{
  Single character: \code{"closed"} | \code{"transient"} | \code{"recurse"}.
}
\description{
  Evaluate a 3x3 matrix against the frozen closure gate:
  \itemize{
    \item \code{closed} — satisfies complement and central symmetry,
      can fold back to palindrome storage;
    \item \code{transient} — computation intermediate state, keep as
      working state, NOT writable to storage;
    \item \code{recurse} — asymmetry is a next-dimension emergence signal.
  }
  Ported from \code{mapping_pack.py closure()}.
}
\examples{
closure_jiugong(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
}
