\name{new_mapping_pack}
\alias{new_mapping_pack}
\title{Construct a mapping pack}
\usage{
new_mapping_pack(id, orbit_table, expand_order, complement_table = list(),
  frozen_symbols, carrier_fn = NULL, gamma_rule = NULL,
  local_center_transform = NULL, closure_policy = list(),
  version = "0.2.2", description = "")
}
\arguments{
  \item{id}{Single character, unique pack id.}
  \item{orbit_table}{Named list of orbit entries (A/B/C/D/e -> coords).}
  \item{expand_order}{Character vector, center-outward expansion order.}
  \item{complement_table}{Named list, symbol complement mapping.}
  \item{frozen_symbols}{Character vector, legal symbol alphabet.}
  \item{carrier_fn}{Function, carrier generator (e.g. carrier_11x11).}
  \item{gamma_rule}{Function (pal) -> 3x3 matrix, or NULL (default
    Gamma rule used).}
  \item{local_center_transform}{Function (symbol) -> symbol, or NULL
    (identity). The pal-jiugong pack chooses tolower.}
  \item{closure_policy}{List of named closure rules consumed by
    closure_check / transition_policy.}
  \item{version}{Single character, pack version.}
  \item{description}{Single character, human-readable description.}
}
\value{
  Object of class \code{visualr_mapping_pack}.
}
\description{
  Create an immutable mapping-pack object that DRIVES all
  storage-computation mappings (P0-1/P0-2 fix: mapping_pack_id is no
  longer a passive label; the pack is the sole authority for orbit,
  gamma, carrier, transform and closure rules). The full rule surface
  is hashed into pack identity; assert_pack() recomputes the canonical
  hash on every resolve and FAILS CLOSED on mismatch.
}
\examples{
pack <- new_mapping_pack(
  id = "example-pack",
  orbit_table = visualR:::ORBIT_TABLE,
  expand_order = visualR:::EXPAND_ORDER,
  frozen_symbols = c("A","B","C","D","e")
)
}
