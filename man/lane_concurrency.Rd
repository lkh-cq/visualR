\name{execute_lanes_parallel}
\alias{execute_lanes_parallel}
\alias{run_topology_pipeline_parallel}
\alias{resolve_lane_engine}
\title{Concurrent lane execution for the Topology Operator ABI}
\usage{
execute_lanes_parallel(snap, kernels = NULL,
                       engine = c("auto", "multicore", "psock", "serial"),
                       ncores = NULL)

run_topology_pipeline_parallel(pal, kernels = NULL,
                                engine = c("auto", "multicore", "psock", "serial"),
                                ncores = NULL)
}
\arguments{
  \item{snap}{A \code{visualr_snapshot}.}
  \item{pal}{A \code{visualr_pal}.}
  \item{kernels}{Named lane-kernel functions, or a kernel-name spec.}
  \item{engine}{Execution fabric: automatic, fork/multicore, PSOCK,
    or serial.}
  \item{ncores}{Number of workers; defaults to detected cores minus one.}
}
\value{
  \code{execute_lanes_parallel} returns lane deltas plus requested and
  effective engine, worker count, fallback flag, and execution label.
  \code{run_topology_pipeline_parallel} returns the full pipeline result
  plus the lane execution report.
}
\description{
  Executes one lane per restored orbit plus the singularity lane over
  one frozen snapshot. Serial, PSOCK, and fork execution must be
  semantically identical; only execution performance may differ.
  Windows multicore requests are reported as platform fallback, while
  PSOCK provides the portable process backend.
}
\examples{
p <- new_pal_state(c("A", "B", "C", "D"), "e")
snap <- snapshot(new_topology_carrier(p))
r <- execute_lanes_parallel(snap, lane_kernels("identity"),
                            engine = "serial", ncores = 1L)
r$execution
}
