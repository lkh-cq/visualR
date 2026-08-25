\name{benchmark_numeric_observers}
\alias{benchmark_numeric_observers}
\alias{benchmark_tap_compiler}
\title{v0.6.2 numerical and CPU evidence benchmarks}
\usage{
benchmark_numeric_observers(
  sizes = c(3L, 11L, 31L),
  reps = 20L,
  batches = 3L
)

benchmark_tap_compiler(
  widths = c(9L, 33L, 65L),
  levels = 4L,
  kernel_offsets = c(-1L, 0L, 1L),
  convolutions_per_level = 2L,
  reps = 20L,
  batches = 3L
)
}
\arguments{
\item{sizes}{Unique positive square side lengths, at most 257.}
\item{reps}{Positive timed repetitions per batch.}
\item{batches}{Positive number of timing batches; medians are reported.}
\item{widths}{Unique positive odd PAL path widths, at most 129.}
\item{levels}{Positive number of dilation levels.}
\item{kernel_offsets}{Ordered unique integer tap offsets.}
\item{convolutions_per_level}{Positive passes per level.}
}
\value{
A data frame of platform-dependent timing and static object-size evidence.
The tap benchmark also reports exact schedule equivalence and speedup
relative to the R implementation.
}
\description{
Provides bounded, reproducible CPU evidence for the v0.6.2 observation
pipeline and the v0.6.1 R/C99 tap-schedule boundary. R remains semantic
authority. Timings are diagnostic evidence, not frozen guarantees, and
\code{result_bytes} is not a process peak-memory measurement.
}
\details{
The numeric benchmark covers field construction, lossless polar metadata,
unitary spectral execution and inversion, address-aware gradients, bias
features, and deterministic scheduling. The tap benchmark refuses to report
C99 performance unless the complete native schedule is identical to R.
}
\examples{
\donttest{
benchmark_numeric_observers(sizes = c(3L, 11L), reps = 5L)
benchmark_tap_compiler(widths = c(9L, 33L), reps = 5L)
}
}
