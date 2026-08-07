\name{concurrency_report}
\alias{concurrency_report}
\title{Benchmark batch_compute concurrency speedup}
\usage{
concurrency_report(sizes = c(200L, 1000L, 5000L),
  ncores_vec = c(1L, 2L, 4L), op = "orbit_rotate",
  trials = 3L)
}
\arguments{
  \item{sizes}{Integer vector of task sizes (number of pal states).}
  \item{ncores_vec}{Integer vector of cores to test (at least 1).}
  \item{op}{Single character, operator applied (default "orbit_rotate").}
  \item{trials}{Integer, number of timing trials per cell (default 3).}
}
\value{
Data.frame with one row per (size, ncores) pair and columns:
\code{size}, \code{ncores}, \code{serial_s} (elapsed at 1 core),
\code{parallel_s} (elapsed at requested cores),
\code{speedup} (\code{serial_s / parallel_s}), \code{fallback}
(logical, whether requested cores actually ran).
}
\description{
Reproducible measurement of concurrent-to-serial speedup for
\code{batch_compute} across task sizes and core counts. This is the
v0.4.x Efficiency-gate "concurrent throughput" measurement
(DEVELOPMENT_PLAN_v0.5.0.md §10).

Speedup is bounded (fork overhead limits linear scaling); the result
is reported honestly. Determinism of \code{batch_compute} is assumed
(verified separately); this measures speedup, not correctness.
}
\examples{
concurrency_report(sizes = c(200, 1000), ncores_vec = c(1, 2, 4), trials = 1)
}