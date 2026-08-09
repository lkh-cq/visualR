\name{gradient_layers}
\alias{gradient_layers}
\alias{emerge_weight}
\alias{emerge_by_layers}
\alias{project_gradient_window}
\alias{verify_gradient_emergence}
\title{Gradient emergence: layered expansion, not matrix filling}
\usage{
gradient_layers(depth)

emerge_weight(layer_index, ring_size, model = "decay")

emerge_by_layers(depth, symbols = c("e", "D", "C", "B", "A"))

project_gradient_window(emergence, radius)

verify_gradient_emergence(emergence)
}
\arguments{
  \item{depth}{Non-negative integer; number of gradient layers beyond
    the center.}
  \item{layer_index}{Integer; the gradient layer (0 = center).}
  \item{ring_size}{Integer; number of positions in that layer.}
  \item{model}{Weight model; default \code{"decay"}.}
  \item{symbols}{Symbol table ordered from the CENTER outward (default
    e,D,C,B,A).}
  \item{emergence}{Result of \code{emerge_by_layers}.}
  \item{radius}{Integer; half-width of the observation window.}
}
\value{
  \code{gradient_layers} returns a \code{visualr_gradient_layers} list
  of position frames (one batch per gradient layer; layer k>0 has 4k
  positions).

  \code{emerge_weight} returns a numeric structural weight.

  \code{emerge_by_layers} returns the emergence structure: layers,
  depth_map, symbols, needs_extension, extension_note.

  \code{project_gradient_window} returns a character matrix with NA in
  the four corners outside the diamond.

  \code{verify_gradient_emergence} returns named invariant checks and
  an overall ok flag.
}
\description{
  Implements the gradient-expansion view: expansion proceeds by
  gradient layers, each batch being one layer — NOT filling a fixed
  matrix once. The matrix is only a local observation window of an
  infinite recursive expansion; the gradient stream is the working
  structure. Positions carry topological information; the emergence
  weight is a structural allocation of compute/verification resources,
  not a statistical frequency. Deep layers that exceed the symbol table
  are reported as needing extension instead of being invented.
}
\examples{
g <- gradient_layers(2L)
nrow(g[[1L]]); nrow(g[[2L]]); nrow(g[[3L]])
e <- emerge_by_layers(4L)
project_gradient_window(e, radius = 2L)
verify_gradient_emergence(e)
}
