\name{dimension_series}
\alias{dimension_series}
\alias{gradient_lattice}
\alias{gradient_metadata}
\alias{gradient_residual}
\alias{audit_dimension_sample}
\title{Equation-core probes: candidate series, gradients, and residuals}
\usage{
dimension_series(s_max = 8L, d_max = 8L)

gradient_lattice(width)

gradient_metadata(lattice)

gradient_residual(observed, predicted, weights = NULL)

audit_dimension_sample(sample)
}
\arguments{
  \item{s_max}{Non-negative integer; largest PAL storage index.}
  \item{d_max}{Positive integer; largest carrier index.}
  \item{width}{Positive integer matrix width.}
  \item{lattice}{A \code{visualr_gradient_lattice}.}
  \item{observed}{Numeric observed/source field.}
  \item{predicted}{Numeric candidate-generated field.}
  \item{weights}{Optional non-negative numeric weights with the same
    dimensions as the fields.}
  \item{sample}{A non-empty square numeric or character matrix.}
}
\value{
  \code{dimension_series} returns a \code{visualr_dimension_series}
  containing separate candidate PAL and carrier sequences. The status
  remains \code{candidate_not_frozen}.

  \code{gradient_lattice} returns coordinate metadata with an explicit
  odd/even center mode. \code{gradient_metadata} summarizes the lattice.
  \code{gradient_residual} returns element-wise residuals and numeric
  error metrics. \code{audit_dimension_sample} records shape/parity and
  gradient facts without interpreting symbolic values.
}
\description{
  Auditable primitives for the next visualR stage: equation-core
  development. The functions deliberately keep PAL storage index s,
  carrier index d, recursive type layer r, and runtime step t separate.

  The candidate relations are L_s = 2s + 1, W_d = d + 2, and
  Q_d = W_d + d. They are not promoted to frozen laws by this API.
  Gradient metadata is coordinate structure only; it does not invent
  values for unknown 5x5/6x6 samples. Numeric residuals provide the
  error instrument to use after a candidate generative equation G_d is
  supplied.
}
\examples{
s <- dimension_series(s_max = 4L, d_max = 5L)
g3 <- gradient_lattice(3L)
g4 <- gradient_lattice(4L)
gradient_metadata(g4)
gradient_residual(matrix(1:4, 2, 2), matrix(1:4, 2, 2))
}
