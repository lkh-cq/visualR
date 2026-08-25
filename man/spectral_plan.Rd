\name{compile_spectral_plan}
\alias{compile_spectral_plan}
\alias{execute_spectral_plan}
\alias{inverse_spectral}
\alias{angular_modes}
\alias{print.visualr_spectral_plan}
\alias{print.visualr_spectrum}
\alias{print.visualr_angular_modes}
\title{Explicit unitary spectral observations}
\usage{
compile_spectral_plan(
  field,
  domain = c("path", "carrier"),
  boundary_policy,
  normalization = "unitary",
  center_shift = "none"
)

execute_spectral_plan(field, plan)

inverse_spectral(spectrum)

angular_modes(field, chart, modes, weights)

\method{print}{visualr_spectral_plan}(x, ...)

\method{print}{visualr_spectrum}(x, ...)

\method{print}{visualr_angular_modes}(x, ...)
}
\arguments{
\item{field}{A matching \code{visualr_numeric_field}.}
\item{domain}{Transform domain, matching \code{field$domain}.}
\item{boundary_policy}{Required explicit \code{"finite_window"} or
\code{"periodic"}. Periodic execution is refused for open fields.}
\item{normalization}{Only \code{"unitary"} is supported.}
\item{center_shift}{Only \code{"none"} is supported in v0.6.2.}
\item{plan}{A \code{visualr_spectral_plan}.}
\item{spectrum}{A \code{visualr_spectrum}.}
\item{chart}{A matching lossless \code{visualr_polar_chart}.}
\item{modes}{Finite integer angular mode indices.}
\item{weights}{Required finite, non-negative sampling weight per
address. Samples whose angle is undefined must have zero weight.}
\item{x}{A spectral object for its print method.}
\item{...}{Unused.}
}
\value{
A compiled plan, spectrum, reconstructed numeric field, or direct
angular-mode result, according to the called function.
}
\description{
Provides unitary one- or two-dimensional Fourier observations with
source/address hashes, exact shape, explicit boundary policy, and
Parseval-compatible normalization. Direct angular modes operate on the
original samples and declared weights without polar interpolation.
}
\details{
A finite-window spectrum describes only the supplied samples. It does
not imply padding or periodic continuation. Plans currently require a
fully observed mask because no masked-sample transform policy has been
declared. A spectrum is an
observation view and does not establish convolution equivalence or a
trainable TCN. Stale source identity, address order, or shape fails
closed.
}
\examples{
field <- new_numeric_field(
  matrix(1:9, 3L), value_semantics = "fixture",
  boundary_state = "closed"
)
plan <- compile_spectral_plan(field, "carrier", "finite_window")
spectrum <- execute_spectral_plan(field, plan)
inverse_spectral(spectrum)
}
