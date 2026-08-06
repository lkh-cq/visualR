\name{new_pal_state}
\alias{new_pal_state}
\title{Construct a visualr_pal State Object}
\description{
  Creates a new \code{visualr_pal} S3 object representing a palindrome-addressed
  topological state with shells (containment chain) and core (central singularity).
}
\usage{
new_pal_state(shells, core,
              mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
              provenance = list())
}
\arguments{
  \item{shells}{Character vector. The containment chain from outer to inner.
    Any non-negative length is allowed. No NA values.}
  \item{core}{Character scalar (length 1). The central singularity. No NA.}
  \item{mapping_pack_id}{Character scalar. Versioned mapping pack identifier.
    Defaults to \code{"pal-jiugong-v0.1"}.}
  \item{provenance}{List. Provenance metadata. Defaults to empty list.}
}
\value{
  A \code{visualr_pal} S3 object with fields: \code{shells}, \code{core},
  \code{mapping_pack_id}, \code{provenance}.
}
\examples{
S4 <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
S0 <- new_pal_state(shells = character(0), core = "X")
}
