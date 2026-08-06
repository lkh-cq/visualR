\name{register_operator}
\alias{register_operator}
\title{Register a custom emergence operator}
\usage{
register_operator(name, fn)
}
\arguments{
  \item{name}{Single character, operator name.}
  \item{fn}{Function taking a 3x3 matrix and returning a 3x3 matrix.}
}
\value{
  Invisible \code{NULL}; registers for \code{compute_jiugong()}.
}
\description{
  Add a shape-preserving operator Ω: 3x3 -> 3x3 to the registry.
  The operator must read a snapshot and commit atomically
  (copy-on-modify in R gives this naturally).
}
\examples{
register_operator("flip_diag", function(M) t(M))
}
