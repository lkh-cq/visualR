\name{block_contract}
\alias{block_contract}
\alias{check_shape_preserving}
\alias{print.visualr_block_abi}
\title{Shape-preserving block ABI contract}
\usage{
block_contract(block_name, input_shape, output_shape, adaptation = NULL)

check_shape_preserving(input_shape, output_shape)

\method{print}{visualr_block_abi}(x, ...)
}
\arguments{
\item{block_name}{character(1), block identifier.}

\item{input_shape}{integer vector, declared input dimensions.}

\item{output_shape}{integer vector, declared output dimensions.}

\item{adaptation}{character(1) or NULL. Required when shapes differ;
describes the explicit adaptation (e.g. \code{"1x1 downsample"}).}

\item{x}{a \code{visualr_block_abi} object.}

\item{...}{unused.}
}
\value{
\code{check_shape_preserving()} returns logical(1), TRUE when the two
shapes are identical.
\code{block_contract()} returns a list of class \code{visualr_block_abi}
with block_name, input_shape, output_shape, shape_preserving,
adaptation and abi_ok. Fail-closed: a shape change without an
adaptation string yields abi_ok = FALSE.
}
\description{
Applies TCN's TemporalBlock discipline: a compute block is
shape-preserving or it declares an explicit adaptation. Blocks compose
by shape contract alone; implicit shape changes are refused.
}
\examples{
check_shape_preserving(c(3L, 3L), c(3L, 3L))   # TRUE
check_shape_preserving(c(3L, 3L), c(11L, 11L)) # FALSE
block_contract("identity_lane", c(3L, 3L), c(3L, 3L))
block_contract("carrier_jump", c(3L, 3L), c(11L, 11L),
               adaptation = "11x11 carrier view")
}
