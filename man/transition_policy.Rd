\name{transition_policy}
\alias{transition_policy}
\title{Transition policy: what to do with a non-closed state}
\usage{
transition_policy(grid, mapping_pack_id = DEFAULT_MAPPING_PACK_ID)
}
\arguments{
  \item{grid}{A 3x3 matrix.}
  \item{mapping_pack_id}{Single character, pack id.}
}
\value{
  Single character: "promote" | "transient" | "recurse" | "reject".
}
\description{
  Scheduling decision layer, SEPARATE from the closure fact (P0-5):
  closed -> "promote" (fold back to storage); symmetry-broken ->
  "recurse" (EXPERIMENTAL scheduling candidate, P0-7); illegal
  symbols -> "reject"; otherwise -> "transient" (keep as working
  state). Change the policy here without touching the closure fact.
}
\examples{
transition_policy(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
}
