\name{reservoir_runtime}
\alias{new_reservoir}
\alias{new_reservoir_pipe}
\alias{phase_sequence}
\alias{advance_pipes}
\alias{route_pipes}
\alias{allocate_pipes}
\alias{reservoir_topology}
\alias{reservoir_step}
\alias{print.visualr_reservoir}
\alias{print.visualr_allocation}
\alias{print.visualr_sample_topology}
\alias{print.visualr_reservoir_step}
\title{Distributed Residual Reservoir Runtime}
\description{
An experimental runtime in which multiple positioned local pipes sample one
residual field at the same logical instant. Joint allocation enforces both
pipe budgets and node draw limits; the commit retains sampled position
relations as topology.
}
\usage{
new_reservoir(signal, position = NULL, supply = NULL,
  capacity = NULL, node_id = NULL, metadata = list())

new_reservoir_pipe(id, budget, phase = 0,
  phase_step = sqrt(2) - 1, bandwidth = 0.2, metadata = list())

phase_sequence(n, seed = 0, step = sqrt(2) - 1)

advance_pipes(pipes, steps = 1L)

route_pipes(reservoir, pipes, k = NULL)

allocate_pipes(reservoir, pipes, preferences = NULL,
  tolerance = 1e-10, max_iter = 1000L)

reservoir_topology(reservoir, allocation, threshold = 1e-12)

reservoir_step(reservoir, pipes, preferences = NULL, k = NULL,
  tolerance = 1e-10, max_iter = 1000L)

\method{print}{visualr_reservoir}(x, ...)

\method{print}{visualr_allocation}(x, ...)

\method{print}{visualr_sample_topology}(x, ...)

\method{print}{visualr_reservoir_step}(x, ...)
}
\arguments{
  \item{signal}{Finite numeric signal value at each node.}
  \item{position}{Numeric node-by-dimension position matrix.}
  \item{supply}{Non-negative residual supply at each node.}
  \item{capacity}{Non-negative per-step node draw limit.}
  \item{node_id}{Unique non-empty node identifiers.}
  \item{metadata}{Arbitrary metadata retained locally. The router does not
  inspect it.}
  \item{id}{Unique local pipe identifier.}
  \item{budget}{Positive per-step pipe draw budget.}
  \item{phase}{Current modular sampling phase.}
  \item{phase_step}{Finite modular phase increment.}
  \item{bandwidth}{Positive spatial bandwidth over normalised positions.}
  \item{n}{Number of modular phase points.}
  \item{seed}{Starting modular phase.}
  \item{step}{Modular phase increment.}
  \item{pipes}{One \code{visualr_reservoir_pipe} or a list of pipes.}
  \item{steps}{Number of phase increments.}
  \item{reservoir}{A \code{visualr_reservoir}.}
  \item{k}{Optional number of nearest nodes retained for each pipe.}
  \item{preferences}{Optional non-negative pipe-by-node preference matrix.}
  \item{tolerance}{Allocation and conservation tolerance.}
  \item{max_iter}{Maximum simultaneous water-filling rounds.}
  \item{allocation}{A \code{visualr_allocation} or allocation matrix.}
  \item{threshold}{Positive threshold defining sampled support.}
  \item{x}{Object printed by an S3 method.}
  \item{...}{Additional print arguments, currently unused.}
}
\details{
The runtime deliberately separates signal from resource supply. Allocation is
computed in simultaneous rounds from one snapshot. When a node is
oversubscribed, every competing proposal is scaled by the same factor. No
pipe can exceed its budget and no node can exceed the smaller of its residual
supply and per-step capacity.

\code{phase_sequence()} and \code{phase_step} make non-periodic modular
scheduling executable. An irrational phase increment is an optional routing
hypothesis; it is not stored as a node class and floating-point computation is
not treated as a proof of irrationality.
}
\value{
\code{new_reservoir()} returns a \code{visualr_reservoir};
\code{new_reservoir_pipe()} returns a \code{visualr_reservoir_pipe};
\code{route_pipes()} returns a preference matrix;
\code{allocate_pipes()} returns a \code{visualr_allocation};
\code{reservoir_topology()} returns a \code{visualr_sample_topology}; and
\code{reservoir_step()} returns a \code{visualr_reservoir_step} containing
the input snapshot, joint allocation, local outputs, sampled topology, next
reservoir state, next pipe phases, and a supply-conservation record.
}
\examples{
field <- new_reservoir(
  signal = c(2, -1, 4, 3, 6, 5),
  position = cbind(x = seq(0, 1, length.out = 6)),
  supply = rep(1, 6),
  capacity = rep(0.5, 6)
)

pipes <- list(
  new_reservoir_pipe("local-a", 0.8, phase = 0),
  new_reservoir_pipe("local-b", 0.8, phase = 0.5,
                     phase_step = (sqrt(5) - 1) / 2)
)

result <- reservoir_step(field, pipes, k = 3)
result$conservation
result$outputs
result$topology
}
