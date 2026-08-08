\name{batch_compute}
\alias{batch_compute}
\title{Parallel bulk computation across many pal states}
\usage{
batch_compute(pals, op = "identity", carrier = "auto", ncores = NULL,
  engine = c("auto", "multicore", "psock", "serial"))
}
\arguments{
  \item{pals}{List of \code{visualr_pal} objects.}
  \item{op}{Single character, operator name.}
  \item{carrier}{Single character, carrier for materialize
    (default "auto": S_4 -> canonical_jiugong, else gamma_local).}
  \item{ncores}{Integer, number of cores (default: detectCores()-1).}
  \item{engine}{Concurrency engine: "auto" (default: multicore on Unix,
    psock on Windows), "multicore" (mclapply, Unix only -- falls back
    to serial on Windows), "psock" (PSOCK cluster, works everywhere),
    or "serial". Never silently degrades: the effective engine is
    always reported in the return value.}
}
\value{
  List: n, ncores, requested_cores, fallback, engine, carrier,
  execution ("serial" | "serial-fallback" | "multicore" | "psock"),
  results (per-state action), n_promote, n_transient, n_recurse,
  n_reject, consistent (logical).
}
\description{
  Apply an emergence operator to N pal states in parallel through the
  UNIFIED materialize dispatch. On Unix the default engine is
  \code{mclapply} (fork); on Windows \code{makePSOCKcluster} provides
  true multi-core parallelism (previously serial-only). The effective
  engine and any fallback are always reported -- never silent
  degradation (plan §6).
}
\examples{
batch_compute(list(new_pal_state(c("A","B","C","D"), "e"),
                   new_pal_state(c("A","B","C"), "D")), "identity", ncores = 1)
}
