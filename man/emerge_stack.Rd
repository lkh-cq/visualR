\name{emerge_stack}
\alias{emerge_stack}
\alias{print.visualr_emerge_stack}
\title{Derive an emergence stack from a width list}
\usage{
emerge_stack(widths)

\method{print}{visualr_emerge_stack}(x, ...)
}
\arguments{
\item{widths}{integer vector of carrier widths, length >= 1, all
positive. The first width is the input width.}

\item{x}{a \code{visualr_emerge_stack} object.}

\item{...}{unused.}
}
\value{
A list of class \code{visualr_emerge_stack} with levels (one data
frame row per level: level, width, dilation, shape_preserving,
adaptation, abi_ok), n_levels, widths and abi_ok (all levels legal).
}
\description{
Builds an ordered emergence stack from a carrier width list, mirroring
TCN's num_channels interface: the caller supplies widths, the stack
derives per-level dilation (growth_law "dilation_power") and block ABI
records automatically. Width changes between levels receive explicit
carrier_adapter adaptation notes -- never implicit.
}
\examples{
emerge_stack(c(3L, 3L, 3L))     # 3 shape-preserving levels
emerge_stack(c(3L, 4L, 4L))     # level 2 adapts 3x3 -> 4x4
}
