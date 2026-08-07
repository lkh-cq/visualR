\name{pal_pipe}
\alias{pal_pipe}
\title{Interactive pipeline: storage -> compute -> fold-back}
\usage{
pal_pipe(x, op = "identity", verbose = TRUE)
}
\arguments{
  \item{x}{A \code{visualr_pal} object OR a palindrome grammar string.}
  \item{op}{Single character, operator name (see \code{compute_jiugong}).}
  \item{verbose}{Logical, print the pipeline trace. Default TRUE.}
}
\value{
  List: input, expanded (jiugong matrix), computed (operator output),
  closure, foldable, fold_back (pal state if foldable, else NULL).
}
\description{
  One-command interactive workflow. Takes a pal state (or grammar text),
  expands it, applies an emergence operator, runs the closure gate, and
  reports the fold-back decision. Designed for REPL experimentation:
  every step is visible. R interactive REPL is the benchmark for the
  consciousness-bus storage -> compute -> fold-back loop.
}
\examples{
pal_pipe("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
}
