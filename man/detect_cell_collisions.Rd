\name{detect_cell_collisions}
\alias{detect_cell_collisions}
\title{Detect shared-resource (cell) collisions among states}
\usage{
detect_cell_collisions(states)
}
\arguments{
  \item{states}{A list of \code{visualr_transported_state}.}
}
\value{
  A named list of index vectors: each entry groups the indices of states that
  declare the same target cell (cell/chart/layer key). Only contested cells
  (>= 2 states) are kept.
}
\description{
  \code{detect_cell_collisions} finds two or more states declaring the same
  target cell, keyed by (cell, chart, layer) of each state's current
  \code{position}. It is the first stage of the shared-resource
  arbitration plugin and is semantically blind — it reads only positions and
  never merge content.
}
\details{
  A "target cell" is the cell of a state's current position (from its last
  step's \code{to}). Collision is a pure positional fact. The output is
  consumed by \code{\link{arbitrate_collisions}}.
}
\examples{
p <- new_position_state("/a", 0, "alpha")
mk <- function(id) new_transported_state(new_merge("p", id, "A", 1L), p,
                                         new_transmission_path(id, p), list())
detect_cell_collisions(list(mk("m1"), mk("m2")))
}