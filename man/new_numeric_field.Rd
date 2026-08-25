\name{new_numeric_field}
\alias{new_numeric_field}
\alias{validate_numeric_field}
\alias{print.visualr_numeric_field}
\title{Address-bound numeric fields}
\usage{
new_numeric_field(
  x,
  values = NULL,
  value_semantics,
  unit = NULL,
  mask = NULL,
  boundary_state = NULL,
  signal = NULL
)

validate_numeric_field(field)

\method{print}{visualr_numeric_field}(x, ...)
}
\arguments{
\item{x}{A \code{visualr_pal}, \code{visualr_pal_window},
\code{visualr_dilated_plan}, or numeric/complex matrix.}

\item{values}{Numeric or complex values for PAL/path inputs. Matrix
inputs bind their own values and require this to remain \code{NULL}.}

\item{value_semantics}{A non-empty caller declaration of what the
numbers mean. PAL tokens are never converted to numbers implicitly.}

\item{unit}{Optional unit string. The default is \code{"unspecified"}.}

\item{mask}{Optional non-missing logical visibility flag per address.}

\item{boundary_state}{For matrices, a required explicit
\code{"closed"} or \code{"open"}. PAL/path inputs inherit their window
boundary and reject a conflict.}

\item{signal}{Optional \code{visualr_signal_envelope}.}

\item{field}{A \code{visualr_numeric_field}.}

\item{...}{Unused.}
}
\value{
\code{new_numeric_field()} returns a \code{visualr_numeric_field}.
\code{validate_numeric_field()} returns invisible \code{TRUE} or fails
closed.
}
\description{
Binds finite numeric observations to stable PAL global addresses or to
the column-major row/column addresses of a matrix. Address order,
semantics, units, mask, boundary, mapping-pack identity, signal
metadata, and a source hash remain explicit.
}
\details{
This type is the numerical boundary of visualR v0.6.2. Symbolic PAL
tokens retain only their grammar and topology meaning. A source hash
changes when addresses, values, masks, declarations, or routing
metadata change; stale derived plans therefore fail closed.
}
\examples{
x <- matrix(1:9, nrow = 3L)
field <- new_numeric_field(
  x,
  value_semantics = "ordered fixture",
  unit = "ordinal",
  boundary_state = "closed"
)
validate_numeric_field(field)
}
