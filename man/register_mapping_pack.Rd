\name{register_mapping_pack}
\alias{register_mapping_pack}
\title{Register a mapping pack}
\usage{
register_mapping_pack(pack, overwrite = FALSE)
}
\arguments{
  \item{pack}{A \code{visualr_mapping_pack} object.}
  \item{overwrite}{Logical, allow replacing an existing id.
    Default FALSE (fail closed on duplicates).}
}
\value{
  Invisible NULL.
}
\description{
  Add a pack to the global registry so \code{resolve_mapping_pack()}
  can find it by id. Duplicate ids fail closed unless overwrite=TRUE.
}
\examples{
register_mapping_pack(new_mapping_pack(
  id = "example-pack",
  orbit_table = visualR:::ORBIT_TABLE,
  expand_order = visualR:::EXPAND_ORDER,
  frozen_symbols = c("A","B","C","D","e")
))
}
