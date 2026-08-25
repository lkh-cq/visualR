\name{new_signal_envelope}
\alias{new_signal_envelope}
\alias{compile_signal_schedule}
\alias{print.visualr_signal_envelope}
\alias{print.visualr_signal_schedule}
\title{Explicit multi-timescale signal routing}
\usage{
new_signal_envelope(
  source_kind,
  timescale = c("static", "fast", "slow"),
  density = c("dense", "sparse"),
  update_interval = 1L,
  spatial_scope = "declared",
  persistence = c("persistent", "transient"),
  provenance = "caller:unspecified",
  uncertainty = 0
)

compile_signal_schedule(fields, tick)

\method{print}{visualr_signal_envelope}(x, ...)

\method{print}{visualr_signal_schedule}(x, ...)
}
\arguments{
\item{source_kind}{Non-empty source identifier.}
\item{timescale}{Explicit \code{"static"}, \code{"fast"}, or
\code{"slow"} routing class.}
\item{density}{Explicit \code{"dense"} or \code{"sparse"} routing
class.}
\item{update_interval}{Positive integer tick interval.}
\item{spatial_scope}{Caller-declared spatial scope.}
\item{persistence}{Either \code{"persistent"} or
\code{"transient"}.}
\item{provenance}{Non-empty provenance identifier.}
\item{uncertainty}{Finite observation uncertainty in \code{[0, 1]}.
This is not a correctness probability.}
\item{fields}{Named, non-empty list of
\code{visualr_numeric_field} objects.}
\item{tick}{Positive integer logical tick.}
\item{x}{An envelope or schedule for its print method.}
\item{...}{Unused.}
}
\value{
An envelope or a deterministic schedule containing separate active and
inactive route tables. Payload values are not combined.
}
\description{
Declares signal provenance and scheduling cadence independently from
numeric payloads. Fast/slow and dense/sparse are routing labels, not
inferred biological, neural, metabolic, or quality claims.
}
\examples{
env <- new_signal_envelope(
  "sensor", "fast", "dense", 1L,
  provenance = "example:sensor"
)
field <- new_numeric_field(
  matrix(1:4, 2L), value_semantics = "sensor fixture",
  boundary_state = "closed", signal = env
)
compile_signal_schedule(list(sensor = field), tick = 1L)
}
