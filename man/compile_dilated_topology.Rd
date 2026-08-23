\name{compile_dilated_topology}
\alias{compile_dilated_topology}
\alias{validate_dilated_plan}
\alias{print.visualr_dilated_plan}
\title{Compile a TCN-pattern dilated PAL topology}
\usage{
compile_dilated_topology(
  x,
  levels,
  kernel_offsets = c(-1L, 0L, 1L),
  convolutions_per_level = 2L,
  engine = c("r", "c")
)

validate_dilated_plan(plan)

\method{print}{visualr_dilated_plan}(x, ...)
}
\arguments{
\item{x}{A \code{visualr_pal}, \code{visualr_pal_window}, or compiled
\code{visualr_dilated_plan} for the print method.}

\item{levels}{Integer number of residual levels. Dilation at level
\code{k} is \code{2^(k - 1)}.}

\item{kernel_offsets}{Ordered, unique integer tap offsets.}

\item{convolutions_per_level}{Integer passes per level. The default two
mirrors the structural reference block.}

\item{engine}{\code{"r"} for the semantic reference or \code{"c"} for
the registered C99 integer-address compiler.}

\item{plan}{A \code{visualr_dilated_plan}.}

\item{...}{Unused.}
}
\value{
\code{compile_dilated_topology()} returns a
\code{visualr_dilated_plan}. \code{validate_dilated_plan()} returns
invisible \code{TRUE} or fails closed.
}
\description{
Compiles a PAL address window into explicit nodes, dilated tap edges,
same-address residual edges, and unresolved boundary-frontier edges.
The output is symbolic topology rather than numerical convolution.
}
\details{
The structural reference is \code{locuslab/TCN} at commit
\code{2f8c2b817050206397458dfd1f5a25ce8a32fe65}: fixed kernel,
exponential dilation, two passes per block, and an explicit residual.
This analogy is not a mathematical equivalence claim and no neural
weights or PyTorch behavior are migrated.

R remains semantic authority. The C99 engine returns only the normative
nine-column integer tap schedule; R attaches tokens, boundary state,
outer references, graph identity, and validation. Outside reads become
\code{outer_reference} nodes for open windows or \code{boundary_stop}
nodes for complete solutions. Zero padding is never implicit.
}
\examples{
open_text <- paste0("}", "{B{C{D}C}B}", "{")
w <- open_window_parse(open_text)
plan <- compile_dilated_topology(w, levels = 2L)
validate_dilated_plan(plan)
}
