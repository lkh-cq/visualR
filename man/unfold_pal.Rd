\name{unfold_pal}
\alias{unfold_pal}
\title{Unfold a visualr_pal to Palindrome Vector}
\description{
  Expands a \code{visualr_pal} object into a palindrome character vector:
  \code{c(shells, core, rev(shells))}. The result always has odd length
  \code{2 * length(shells) + 1}.
}
\usage{
unfold_pal(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
  A character vector forming a palindrome.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
unfold_pal(S4)  # c("A","B","C","D","E","D","C","B","A")
}
