\name{bias_features}
\alias{bias_features}
\alias{fit_reference_threshold}
\alias{audit_bias}
\alias{print.visualr_bias_threshold}
\alias{print.visualr_bias_audit}
\title{Structural bias evidence and robust review gates}
\usage{
bias_features(field, chart = NULL, spectrum = NULL, gradient = NULL)

fit_reference_threshold(reference, alpha = 0.05)

audit_bias(features, threshold)

\method{print}{visualr_bias_threshold}(x, ...)

\method{print}{visualr_bias_audit}(x, ...)
}
\arguments{
\item{field}{A \code{visualr_numeric_field}.}
\item{chart}{Optional matching \code{visualr_polar_chart}.}
\item{spectrum}{Optional matching \code{visualr_spectrum}.}
\item{gradient}{Optional matching \code{visualr_field_gradient}.}
\item{reference}{Numeric data frame or matrix with at least three
reference observations in rows and named evidence components in
columns.}
\item{alpha}{Finite tail fraction in \code{(0, 0.5)}.}
\item{features}{Finite named numeric evidence vector whose names and
order exactly match the fitted reference.}
\item{threshold}{A \code{visualr_bias_threshold}.}
\item{x}{A threshold or audit object for its print method.}
\item{...}{Unused.}
}
\value{
\code{bias_features()} returns named evidence. The fitting and audit
functions return \code{visualr_bias_threshold} and
\code{visualr_bias_audit} objects.
}
\description{
Extracts inspectable structural-bias components and compares them with
a robust reference envelope. The gate uses component-wise median and
robust scale normalization followed by the maximum absolute component
score. Optional polar, spectral, and gradient summaries remain separate
named evidence components.
}
\details{
These functions do not estimate a prediction probability. A
probability API remains unavailable until a target definition,
labelled outcomes, leakage-safe temporal splits, an independent
calibration set, calibration diagnostics, and operating thresholds are
all supplied and versioned. Feature-name drift fails closed.
}
\examples{
reference <- data.frame(
  B_boundary = c(0, 0, 1),
  B_coverage = c(0, 0.1, 0.05)
)
gate <- fit_reference_threshold(reference, alpha = 0.1)
audit_bias(c(B_boundary = 0, B_coverage = 0.02), gate)
}
