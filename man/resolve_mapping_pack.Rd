\name{resolve_mapping_pack}
\alias{resolve_mapping_pack}
\title{Resolve a mapping pack by id (fail closed)}
\usage{
resolve_mapping_pack(id)
}
\arguments{
  \item{id}{Single character, pack id.}
}
\value{
  A \code{visualr_mapping_pack} object.
}
\description{
  Look up a registered mapping pack. Unknown id -> error (never
  silently fall back to a default). This is the P0-1 fix: runtime
  rules come from the resolved pack, not global constants.
}
\examples{
resolve_mapping_pack("pal-jiugong-v0.2")
}
