\name{pal_pipe}
\alias{pal_pipe}
\title{Interactive pipeline: storage -> compute -> fold-back}
\usage{
pal_pipe(x, op = "identity", carrier = "auto", verbose = TRUE)
}
\arguments{
  \item{x}{A \code{visualr_pal} object OR a palindrome grammar string.}
  \item{op}{Single character, operator name (see \code{compute_jiugong}).}
  \item{carrier}{Single character, carrier for materialize:
    "auto" (default) | "canonical_jiugong" | "gamma_local" |
    "carrier_11x11".}
  \item{verbose}{Logical, print the pipeline trace. Default TRUE.}
}
\value{
  List: input, carrier (resolved), expanded (working matrix), computed
  (operator output), closed (logical FACT), action
  (promote/transient/recurse/reject), fold_back (pal if promoted, else
  NULL), trace.
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
