\name{benchmark_all}
\alias{benchmark_all}
\title{Run all 7 Efficiency-gate measurements (benchmark prototype)}
\usage{
benchmark_all(overhead_reps = 100L, latency_reps = 50L,
              throughput_n = 2000L)
}
\arguments{
  \item{overhead_reps}{Integer, iterations for the overhead timing.}
  \item{latency_reps}{Integer, iterations for the latency timing.}
  \item{throughput_n}{Integer, batch size for throughput.}
}
\value{
  Invisible named list of data.frames: storage, transfer, ram,
  overhead, latency, throughput.
}
\description{
  One-command reproducible measurement suite covering the v0.5.0
  Efficiency gate: compact stored size, expanded working set, transfer
  size, peak RAM estimate, encode/expand/fold overhead, serial latency,
  concurrent throughput. Prints each measurement table.
}
\examples{
benchmark_all(overhead_reps = 10, latency_reps = 10, throughput_n = 50)
}
