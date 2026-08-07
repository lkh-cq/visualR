\name{materialize}
\alias{materialize}
\title{Materialize a pal state to a working matrix (unified dispatch)}
\usage{
materialize(pal, carrier = "auto")
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
  \item{carrier}{Single character: "auto" (default), "canonical_jiugong",
    "gamma_local", or "carrier_11x11".}
}
\value{
  List with fields: carrier (resolved name), grid (matrix), ok (logical).
}
\description{
  THE single carrier-dispatch entry point (P0-2 fix). All computation
  entry points (pal_pipe, batch_compute, interact) go through this
  function so a given pal state always materializes identically.
  "auto" resolves S_4 to canonical_jiugong, everything else to
  gamma_local.
}
\examples{
materialize(new_pal_state(c("A","B","C","D"), "e"))
}
