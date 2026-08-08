\name{new_topology_cell}
\alias{new_topology_cell}
\alias{new_topology_carrier}
\alias{pal_to_cell}
\alias{snapshot}
\alias{lane_identity}
\alias{execute_lanes}
\alias{barrier}
\alias{reconcile}
\alias{commit}
\alias{run_topology_pipeline}
\alias{cell_to_pal}
\title{Topology Operator ABI v0.1 — high-dimensional operator pipeline}
\usage{
new_topology_cell(core, orbits, phase = NULL, orientation = NULL,
                  origin = list(), payload = list())

new_topology_carrier(pal, cell = NULL, axes = NULL, projection = NULL)

pal_to_cell(pal)

snapshot(carrier)

lane_identity(orbit, phase = "idle")

execute_lanes(snap, kernels = NULL)

barrier(deltas)

reconcile(deltas, cell, mapping_pack_id = DEFAULT_MAPPING_PACK_ID)

commit(reconciled, carrier)

run_topology_pipeline(pal, kernels = NULL)

cell_to_pal(cell, pal_orig)
}
\arguments{
  \item{core}{Single character; the singularity token (e.g. "e").}
  \item{orbits}{Named list with entries A/B/C/D, each a character
    vector of two endpoint tokens (head, tail). All-NA endpoints mark a
    MISSING orbit (shallow PAL states).}
  \item{phase}{Single character or numeric; current phase.}
  \item{orientation}{Single character; orientation label.}
  \item{origin}{List; provenance/origin metadata.}
  \item{payload}{List; channel state.}
  \item{pal}{A \code{visualr_pal} object (source of truth).}
  \item{cell}{A \code{visualr_topology_cell} (default: restored from
    the pal).}
  \item{axes}{Character vector of axis names (default
    space/operator/phase/channel).}
  \item{projection}{Optional 3x3 view (the jiugong projection).}
  \item{carrier}{A \code{visualr_carrier} object.}
  \item{orbit}{Character vector of two endpoints (head, tail), or the
    singularity token for the singleton lane.}
  \item{snap}{A \code{visualr_snapshot} object.}
  \item{kernels}{Named list of lane kernels, names in A/B/C/D/e.}
  \item{deltas}{Result of \code{execute_lanes} (named list A/B/C/D/e).}
  \item{mapping_pack_id}{Character; pack for closure semantics.}
  \item{reconciled}{Result of \code{reconcile}.}
  \item{cell}{A \code{visualr_topology_cell} to re-encode.}
  \item{pal_orig}{The ORIGINAL pal (mapping_pack_id/provenance
    continuity).}
}
\value{
  \code{new_topology_cell} returns a \code{visualr_topology_cell};
  \code{new_topology_carrier} returns a \code{visualr_carrier};
  \code{pal_to_cell} returns a \code{visualr_topology_cell} restored
  in one step; \code{snapshot} returns a \code{visualr_snapshot};
  \code{execute_lanes} returns a named list of lane deltas;
  \code{barrier} returns TRUE or errors; \code{reconcile} returns a
  list (ok/conflicts/phase/action/reconciled_cell); \code{commit}
  returns a new \code{visualr_carrier} (S_(t+1)); \code{run_topology_pipeline}
  returns the full step list.
}
\description{
  Topology Operator ABI v0.1 (frozen direction 2026-08-08): the
  high-dimensional operator concurrency pipeline, NOT serial primitive
  reduction. Pipeline:
  \code{TopologyCarrier -> Snapshot -> Concurrent Lanes -> Reconcile
  -> Commit}.

  The 3x3 jiugong is a PROJECTION of a TopologyCell (one singularity +
  four orbits + phase/orientation/origin/payload), not the runtime's
  dimensional ceiling. The fragile link — PAL -> TopologyCell
  restoration — restores full topology semantics in ONE step (never
  char-by-char); PAL is a generative topology encoding, not flattened
  data. R is the operator language; C/Java are execution fabrics for
  this ABI.
}
\examples{
p <- new_pal_state(c("A", "B", "C", "D"), "e")
cell <- pal_to_cell(p)         # restore orbits in one step
cr <- new_topology_carrier(p)  # carrier with 3x3 projection view
res <- run_topology_pipeline(p) # full ABI loop
res$carrier_out$cell$singularity  # "e" (identity pipeline)
}
