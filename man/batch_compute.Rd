\name{batch_compute}
\alias{batch_compute}
\title{Parallel bulk computation across many pal states}
\usage{
batch_compute(pals, op = "identity", carrier = "auto", ncores = NULL)
}
\arguments{
  \item{pals}{List of \code{visualr_pal} objects.}
  \item{op}{Single character, operator name.}
  \item{carrier}{Single character, carrier for materialize
    (default "auto": S_4 -> canonical_jiugong, else gamma_local).}
  \item{ncores}{Integer, number of cores (default: detectCores()-1).}
}
\value{
  List: n, ncores, carrier, results (per-state action), n_promote,
  n_transient, n_recurse, n_reject, consistent (logical).
}
\description{
  Apply an emergence operator to N pal states in parallel (mclapply
  across available cores). Returns per-state closure verdicts plus a
  consistency summary. R parallel computation is the benchmark engine.
}
\examples{
batch_compute(list(new_pal_state(c("A","B","C","D"), "e"),
                   new_pal_state(c("A","B","C"), "D")), "identity", ncores = 1)
}
