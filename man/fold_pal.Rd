\name{fold_pal}
\alias{fold_pal}
\title{Fold a Palindrome Vector to visualr_pal}
\description{
  Folds a palindrome character vector back into a \code{visualr_pal} object.
  Implements藏归分离 (storage-return separation): only reads the unfolded
  path parameter, never accesses any hidden original object.
  Invariant: \code{fold_pal(unfold_pal(S)) == S} (with default metadata).
}
\usage{
fold_pal(unfolded,
         mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
         provenance = list())
}
\arguments{
  \item{unfolded}{Character vector forming a palindrome (odd length).}
  \item{mapping_pack_id}{Character scalar. Versioned mapping pack identifier.}
  \item{provenance}{List. Provenance metadata.}
}
\value{
  A \code{visualr_pal} S3 object.
}
\examples{
pal <- fold_pal(c("A", "B", "C", "D", "E", "D", "C", "B", "A"))
}
