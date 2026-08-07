\name{new_mapping_pack}
\alias{new_mapping_pack}
\title{Construct a mapping pack}
\usage{
new_mapping_pack(id, orbit_table, expand_order, complement_table = list(),
  frozen_symbols, carrier_fn = NULL, version = "0.2.0", description = "")
}
\arguments{
  \item{id}{Single character, unique pack id.}
  \item{orbit_table}{Named list of orbit entries (A/B/C/D/e -> coords).}
  \item{expand_order}{Character vector, center-outward expansion order.}
  \item{complement_table}{Named list, symbol complement mapping.}
  \item{frozen_symbols}{Character vector, legal symbol alphabet.}
  \item{carrier_fn}{Function, carrier generator (e.g. carrier_11x11).}
  \item{version}{Single character, pack version.}
  \item{description}{Single character, human-readable description.}
}
\value{
  Object of class \code{visualr_mapping_pack}.
}
\description{
  Create an immutable mapping-pack object that DRIVES all
  storage-computation mappings (P0-1 fix: mapping_pack_id is no longer
  a passive label). A pack carries the orbit table, expand order,
  complement table, frozen symbols and carrier generator. Runtime
  resolves the pack by id and uses ITS rules — never global constants.
}
\examples{
pack <- new_mapping_pack(
  id = "example-pack",
  orbit_table = visualR:::ORBIT_TABLE,
  expand_order = visualR:::EXPAND_ORDER,
  frozen_symbols = c("A","B","C","D","e")
)
}
