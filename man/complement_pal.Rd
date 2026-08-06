\name{complement_pal}
\alias{complement_pal}
\title{Complement mapping (C^2 = I)}
\usage{
complement_pal(pal, table = NULL)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
  \item{table}{Optional named character vector defining an involution,
    e.g. \code{c(A="T", T="A")}. Missing symbols map to themselves.
    \code{NULL} (default) = self-complement \code{C(x) = x}.}
}
\value{
  A new \code{visualr_pal} with complemented shells/core symbols.
  Metadata (mapping_pack_id, provenance) is preserved.
}
\description{
  Applies the frozen complement rule from the sanyuan-runtime v0.2 spec.
  Default is self-complement (palindrome head == tail). A custom table
  must be an involution: \code{C(C(x)) = x}, verified at call time.
  Invariant: \code{C^2 = I}.
}
\examples{
complement_pal(new_pal_state(c("A", "B"), "C"))
complement_pal(new_pal_state(c("A","B","C","D"), "e"),
               table = c(A = "T", T = "A", B = "G", G = "B"))
}
