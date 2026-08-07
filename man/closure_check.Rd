\name{closure_check}
\alias{closure_check}
\title{Closure fact check: is this 3x3 matrix closed?}
\usage{
closure_check(grid, mapping_pack_id = DEFAULT_MAPPING_PACK_ID)
}
\arguments{
  \item{grid}{A 3x3 matrix.}
  \item{mapping_pack_id}{Single character, pack whose rules drive the
    check (default: DEFAULT_MAPPING_PACK_ID).}
}
\value{
  Logical: TRUE if closed, FALSE otherwise.
}
\description{
  Structural fact only (P0-5). A matrix is "closed" when it is
  (a) composed of legal symbols from the resolved mapping pack,
  (b) symmetric under central inversion, (c) orbit-complement
  consistent, (d) foldable (fold-back then re-expand reproduces it).
  Scheduling decisions belong in \code{transition_policy()}.
}
\examples{
closure_check(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
}
