\name{detect_symmetries}
\alias{detect_symmetries}
\alias{orbit_partition}
\alias{center_analysis}
\alias{label_reuse}
\alias{audit_sample_topology}
\title{Sample topology analysis: symmetries, orbits, and centers}
\usage{
detect_symmetries(M)

orbit_partition(M, sym = NULL)

center_analysis(M, singularity = "e")

label_reuse(orbits)

audit_sample_topology(M, name = "sample")
}
\arguments{
  \item{M}{A non-empty square character/numeric matrix.}
  \item{sym}{Optional result of \code{detect_symmetries}.}
  \item{singularity}{Character; the semantic center token (default
    "e").}
  \item{orbits}{Result of \code{orbit_partition}.}
  \item{name}{Character; sample name for reporting.}
}
\value{
  \code{detect_symmetries} returns transpose/inversion flags and n.
  \code{orbit_partition} returns a data frame of addresses with orbit
  ids and labels. \code{center_analysis} returns geometric and semantic
  center sets and whether they coincide. \code{label_reuse} returns
  reused labels and a has_reuse flag. \code{audit_sample_topology}
  returns the full structural description of one registered sample.
}
\description{
  Structural analysis of registered PAL sample matrices as evidence.
  The analysis pipeline is symmetry detection -> orbit partition ->
  geometric vs semantic center separation -> label reuse detection.

  Content value cannot replace address: a label appearing in more than
  one orbit is reused, which is the structural proof that position
  carries information independent of value. For the 4x4 sample the
  geometric center set (central 2x2 block) does NOT coincide with the
  semantic center (the e pair on the central anti-diagonal).
}
\examples{
M3 <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
audit_sample_topology(M3, name = "3x3")
M4 <- matrix(c("A","B","C","D","B","C","e","C",
               "C","e","C","B","D","C","B","A"), 4, 4, byrow = TRUE)
audit_sample_topology(M4, name = "4x4")
}
