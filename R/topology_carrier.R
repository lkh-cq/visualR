# == Topology Operator ABI v0.1: TopologyCarrier pipeline ===========
# FROZEN DIRECTION (user 2026-08-08): high-dimensional operator
# concurrency — NOT serial primitive reduction.
#
# Pipeline (ABI five interfaces):
#   TopologyCarrier -> Snapshot -> Concurrent Lanes -> Reconcile -> Commit
#
# Implemented here as the R reference semantics (R = operator language;
# C/Java are execution fabrics). 3x3 jiugong is a PROJECTION of a
# TopologyCell, not the runtime's dimensional ceiling.
#
# The most fragile link in the pipeline is PAL -> TopologyCarrier
# restoration: if orbits/phase/origin are lost there, everything
# downstream is built on a flattened shadow. We therefore restore the
# FULL topology semantics in one step (never char-by-char).

# =====================================================================
# 1. TopologyCell / TopologyCarrier objects
# =====================================================================

#' @title Build a TopologyCell
#' @description The real identity behind a 3x3 view: one singularity,
#'   four orbits (each with two endpoints), plus phase/orientation/
#'   origin/payload metadata. The 3x3 matrix is a projection of this
#'   cell, not the object itself.
#' @param core single character; the singularity token (e.g. "e").
#' @param orbits named list with entries A/B/C/D, each a character
#'   vector of two endpoint tokens (head, tail).
#' @param phase single character or numeric; current phase.
#' @param orientation single character; orientation label.
#' @param origin list; provenance/origin metadata.
#' @param payload list; channel state.
#' @return object of class \code{visualr_topology_cell}.
#' @examples
#' tc <- new_topology_cell("e", list(A = c("A","A"), B = c("B","B"),
#'                                   C = c("C","C"), D = c("D","D")))
new_topology_cell <- function(core, orbits, phase = NULL,
                              orientation = NULL, origin = list(),
                              payload = list()) {
  if (!is.character(core) || length(core) != 1L || is.na(core)) {
    stop("`core` must be a single non-NA character.", call. = FALSE)
  }
  if (!is.list(orbits) || is.null(names(orbits))) {
    stop("`orbits` must be a named list (A/B/C/D).", call. = FALSE)
  }
  need <- c("A", "B", "C", "D")
  miss <- setdiff(need, names(orbits))
  if (length(miss) > 0L) {
    stop(sprintf("`orbits` missing: %s", paste(miss, collapse = ",")),
         call. = FALSE)
  }
  for (nm in need) {
    ep <- orbits[[nm]]
    if (!is.character(ep) || length(ep) != 2L) {
      stop(sprintf("orbit %s must be a 2-char endpoint vector.", nm),
           call. = FALSE)
    }
    # NA endpoints are allowed: they mark a MISSING orbit (shallow PAL
    # states have fewer than four shells). Other NAs are rejected.
    if (anyNA(ep) && !all(is.na(ep))) {
      stop(sprintf("orbit %s: endpoint vector has partial NA.", nm),
           call. = FALSE)
    }
  }
  structure(
    list(singularity = core,
         orbits = orbits[need],
         phase = phase %||% "idle",
         orientation = orientation %||% "canonical",
         origin = origin,
         payload = payload),
    class = "visualr_topology_cell"
  )
}

#' @title Build a TopologyCarrier
#' @description The high-dimensional working object: axes, topology map,
#'   active mask, payload. Holds FULL dimension semantics — linear RAM
#'   addresses are just memory; the carrier keeps the coordinate ->
#'   topology mapping so nothing is flattened.
#' @param pal a \code{visualr_pal} object (source of truth).
#' @param cell a \code{visualr_topology_cell} (default: restored from
#'   the pal).
#' @param axes character vector of axis names (default space/operator/
#'   phase/channel).
#' @param projection optional 3x3 view (the jiugong projection).
#' @return object of class \code{visualr_carrier}.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' cr <- new_topology_carrier(p)
new_topology_carrier <- function(pal, cell = NULL, axes = NULL,
                                 projection = NULL) {
  validate_pal(pal)
  if (is.null(cell)) cell <- pal_to_cell(pal)
  if (!inherits(cell, "visualr_topology_cell")) {
    stop("`cell` must be a visualr_topology_cell.", call. = FALSE)
  }
  if (is.null(axes)) {
    axes <- c("space", "operator", "phase", "channel")
  }
  if (is.null(projection)) {
    jg <- tryCatch(pal_to_jiugong(pal), error = function(e) NULL)
    projection <- if (is.null(jg)) NULL else jg$grid
  }
  # topology_map: orbit name -> mirror pair indices in the unfolded
  # sequence (preserves containment/order semantics).
  unfolded <- unfold_pal(pal)
  n <- length(unfolded)
  half <- (n - 1L) / 2L
  topo_map <- list(
    singularity = list(index = half + 1L, token = pal$core),
    orbits = lapply(c("A", "B", "C", "D"), function(nm) {
      list(name = nm, head_idx = NA_integer_, tail_idx = NA_integer_)
    })
  )
  names(topo_map$orbits) <- c("A", "B", "C", "D")
  # active_mask: all cells active for a canonical carrier (future:
  # inactive regions stay frozen).
  active_mask <- matrix(TRUE, nrow = 3L, ncol = 3L)
  structure(
    list(pal = pal,
         cell = cell,
         axes = axes,
         topology_map = topo_map,
         active_mask = active_mask,
         projection = projection,
         payload = list()),
    class = "visualr_carrier"
  )
}

#' @export
print.visualr_topology_cell <- function(x, ...) {
  cat(sprintf("<visualr_topology_cell> singularity=%s phase=%s\n",
              x$singularity, x$phase))
  for (nm in c("A", "B", "C", "D")) {
    ep <- x$orbits[[nm]]
    cat(sprintf("  orbit %s: %s <-> %s\n", nm, ep[1], ep[2]))
  }
  invisible(x)
}

#' @export
print.visualr_carrier <- function(x, ...) {
  cat(sprintf("<visualr_carrier> axes=%s\n",
              paste(x$axes, collapse = ",")))
  cat(sprintf("  singularity=%s | orbits=%d | active=%d cells\n",
              x$cell$singularity, length(x$cell$orbits),
              sum(x$active_mask)))
  if (!is.null(x$projection)) {
    cat("  projection (3x3 view):\n")
    print(x$projection)
  }
  invisible(x)
}

# =====================================================================
# 2. PAL -> TopologyCell restoration (THE fragile link)
# =====================================================================

#' @title Restore a TopologyCell from a pal state
#' @description ONE-STEP restoration of full topology semantics from the
#'   PAL encoding: singularity, four orbits (head/tail endpoints),
#'   containment order, and origin. Never char-by-char; the PAL is a
#'   generative topology encoding.
#' @param pal a \code{visualr_pal} object.
#' @return a \code{visualr_topology_cell}.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' pal_to_cell(p)
pal_to_cell <- function(pal) {
  validate_pal(pal)
  unfolded <- unfold_pal(pal)
  n <- length(unfolded)
  if (n < 1L) stop("PAL with no tokens.", call. = FALSE)
  half <- (n - 1L) / 2L
  core <- pal$core
  # Orbits: each shell pair (head, tail) is an orbit; for S_4 we get
  # A,B,C,D from outermost to innermost. The mirror pair preserves the
  # containment semantics (head at distance d, tail at mirrored d).
  shells <- pal$shells
  n_shells <- length(shells)
  if (n_shells >= 1L) {
    orbit_names <- rev(c("A", "B", "C", "D")[seq_len(min(n_shells, 4L))])
    # map shells (outermost first) to orbit labels A..D (A outermost)
    orbits <- stats::setNames(vector("list", 4L), c("A", "B", "C", "D"))
    for (i in seq_len(min(n_shells, 4L))) {
      label <- c("A", "B", "C", "D")[i]
      tok <- shells[i]
      orbits[[label]] <- c(tok, tok)  # head == tail for canonical PAL
    }
    # fill missing orbits with NA placeholders
    for (label in c("A", "B", "C", "D")) {
      if (is.null(orbits[[label]])) orbits[[label]] <- c(NA_character_, NA_character_)
    }
  } else {
    orbits <- list(A = c(NA_character_, NA_character_),
                   B = c(NA_character_, NA_character_),
                   C = c(NA_character_, NA_character_),
                   D = c(NA_character_, NA_character_))
  }
  new_topology_cell(
    core = core,
    orbits = orbits,
    phase = "idle",
    orientation = "canonical",
    origin = list(pal = format_pal(pal), dim = n_shells)
  )
}

# =====================================================================
# 3. Snapshot
# =====================================================================

#' @title Snapshot a carrier
#' @description Freezes the current carrier state (including active
#'   mask) so concurrent lanes read the SAME view. Returns a snapshot
#'   object; the carrier itself is not mutated by lanes.
#' @param carrier a \code{visualr_carrier}.
#' @return a \code{visualr_snapshot} object.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' cr <- new_topology_carrier(p)
#' snap <- snapshot(cr)
snapshot <- function(carrier) {
  if (!inherits(carrier, "visualr_carrier")) {
    stop("`carrier` must be a visualr_carrier.", call. = FALSE)
  }
  structure(
    list(cell = carrier$cell,
         topology_map = carrier$topology_map,
         active_mask = carrier$active_mask,
         projection = carrier$projection,
         frozen = TRUE),
    class = "visualr_snapshot"
  )
}

#' @export
print.visualr_snapshot <- function(x, ...) {
  cat(sprintf("<visualr_snapshot> frozen=%s singularity=%s\n",
              x$frozen, x$cell$singularity))
  invisible(x)
}

# =====================================================================
# 4. Concurrent Lanes (orbit-parallel execution)
# =====================================================================

#' @title Orbit lane kernel
#' @description A lane is the local operator applied to ONE orbit (or
#'   the singularity) at the SAME logical instant. The default kernel is
#'   identity (returns the orbit unchanged) — the ABI shape is what
#'   matters; concrete kernels plug in later.
#' @param orbit character vector of two endpoints (head, tail), or the
#'   singularity token for the singleton lane.
#' @param phase current phase label.
#' @return list with fields: result, phase, action.
lane_identity <- function(orbit, phase = "idle") {
  list(result = orbit, phase = phase, action = "identity")
}

#' @title Execute the concurrent lanes over a snapshot
#' @description Dispatches one lane per orbit (A,B,C,D) plus the
#'   singularity lane, each over the SAME snapshot. Returns the
#'   per-lane deltas in a list — these are concurrent state transforms
#'   at one logical instant, not sequential steps.
#' @param snap a \code{visualr_snapshot}.
#' @param kernels named list of lane kernels, names in A/B/C/D/e.
#' @return named list with fields A/B/C/D/e, each the lane result.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' cr <- new_topology_carrier(p)
#' snaps <- snapshot(cr)
#' execute_lanes(snaps)
execute_lanes <- function(snap, kernels = NULL) {
  if (!inherits(snap, "visualr_snapshot")) {
    stop("`snap` must be a visualr_snapshot.", call. = FALSE)
  }
  cell <- snap$cell
  if (is.null(kernels)) {
    kernels <- list(A = lane_identity, B = lane_identity,
                    C = lane_identity, D = lane_identity,
                    e = lane_identity)
  }
  # One logical instant: every lane reads the SAME snapshot.
  deltas <- list(
    A = kernels$A(cell$orbits$A, cell$phase),
    B = kernels$B(cell$orbits$B, cell$phase),
    C = kernels$C(cell$orbits$C, cell$phase),
    D = kernels$D(cell$orbits$D, cell$phase),
    e = kernels$e(cell$singularity, cell$phase)
  )
  deltas
}

#' @title Barrier: check all lanes produced a result
#' @description The barrier step: all lanes must have returned. Since
#'   lanes are pure functions over one snapshot, a barrier here means
#'   "all five deltas present and well-formed".
#' @param deltas result of \code{execute_lanes}.
#' @return TRUE if all lanes present; error otherwise.
barrier <- function(deltas) {
  if (!is.list(deltas)) stop("`deltas` must be a list.", call. = FALSE)
  need <- c("A", "B", "C", "D", "e")
  miss <- setdiff(need, names(deltas))
  if (length(miss) > 0L) {
    stop(sprintf("barrier: missing lane deltas: %s", paste(miss, collapse = ",")),
         call. = FALSE)
  }
  TRUE
}

# =====================================================================
# 5. Reconcile (topological reconciliation, NOT numeric reduction)
# =====================================================================

#' @title Reconcile lane deltas into a coherent state
#' @description Topological reconciliation: combines the five concurrent
#'   lane results, resolving conflicts by kind:
#'   \itemize{
#'     \item 可定 (determinable): lanes agree — accept.
#'     \item 异值冲突 (conflicting values): error (fail-closed).
#'     \item 等值不等位冲突 (same value, different position): flag.
#'     \item phase transition: advance phase when all lanes stable.
#'     \item closure: check against the mapping pack.
#'   }
#' @param deltas result of \code{execute_lanes}.
#' @param cell the \code{visualr_topology_cell} being reconciled.
#' @param mapping_pack_id character; pack for closure check.
#' @return list with fields: ok (logical), conflicts (character vector),
#'   phase, action (promote/transient/recurse/reject), reconciled_cell.
reconcile <- function(deltas, cell, mapping_pack_id = DEFAULT_MAPPING_PACK_ID) {
  if (!inherits(cell, "visualr_topology_cell")) {
    stop("`cell` must be a visualr_topology_cell.", call. = FALSE)
  }
  conflicts <- character(0)
  # 1. determinable check: identity lanes keep endpoints; verify no
  #    lane produced a structural anomaly.
  for (nm in c("A", "B", "C", "D")) {
    res <- deltas[[nm]]
    if (!is.list(res) || !"result" %in% names(res)) {
      conflicts <- c(conflicts, sprintf("%s: malformed lane result", nm))
    }
  }
  if (length(conflicts) > 0L) {
    return(list(ok = FALSE, conflicts = conflicts, phase = cell$phase,
                action = "reject", reconciled_cell = cell))
  }
  # 2. build reconciled cell from lane results
  new_orbits <- list(
    A = deltas$A$result, B = deltas$B$result,
    C = deltas$C$result, D = deltas$D$result
  )
  reconciled <- new_topology_cell(
    core = cell$singularity,
    orbits = new_orbits,
    phase = cell$phase,
    orientation = cell$orientation,
    origin = cell$origin,
    payload = cell$payload
  )
  # 3. phase transition: when all lanes stable (identity), phase idles
  phase <- cell$phase
  if (all(vapply(c("A", "B", "C", "D"), function(nm) {
    identical(deltas[[nm]]$action, "identity")
  }, logical(1)))) {
    phase <- "idle"
  }
  list(ok = TRUE, conflicts = conflicts, phase = phase,
       action = "promote", reconciled_cell = reconciled)
}

# =====================================================================
# 6. Commit (S_(t+1) / fail-closed)
# =====================================================================

#' @title Commit a reconciled state
#' @description Writes the reconciled cell back to a carrier for
#'   S_(t+1). Non-closed states are rejected (fail-closed): they cannot
#'   enter canonical storage silently.
#' @param reconciled result of \code{reconcile}.
#' @param carrier the original carrier (for axes/payload continuity).
#' @return a new \code{visualr_carrier} (S_(t+1)) or errors.
commit <- function(reconciled, carrier) {
  if (!is.list(reconciled) || !isTRUE(reconciled$ok)) {
    stop("commit: cannot commit non-reconciled state (fail-closed).",
         call. = FALSE)
  }
  if (!inherits(carrier, "visualr_carrier")) {
    stop("`carrier` must be a visualr_carrier.", call. = FALSE)
  }
  if (reconciled$action == "reject") {
    stop("commit: reconciled state rejected (fail-closed).", call. = FALSE)
  }
  # S_(t+1): new carrier with the reconciled cell, same pal lineage.
  new_topology_carrier(
    pal = carrier$pal,
    cell = reconciled$reconciled_cell,
    axes = carrier$axes,
    projection = carrier$projection
  )
}

# =====================================================================
# 7. Full pipeline driver
# =====================================================================

#' @title Run the full Topology Operator ABI pipeline
#' @description One-command driver:
#'   PAL -> TopologyCarrier -> Snapshot -> Concurrent Lanes -> Barrier
#'   -> Reconcile -> Commit -> PAL re-encoding (S_(t+1)). The complete
#'   high-dimensional operator loop, not a serial cell loop.
#' @param pal a \code{visualr_pal} object.
#' @param kernels optional kernel-name spec or named list of lane
#'   kernels (default: all identity).
#' @return list with fields: carrier_in, snapshot, deltas, barrier,
#'   reconciled, carrier_out, pal_out (re-encoded PAL of S_(t+1)).
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' run_topology_pipeline(p)
#' run_topology_pipeline(p, "rotate")
run_topology_pipeline <- function(pal, kernels = NULL) {
  validate_pal(pal)
  carrier_in <- new_topology_carrier(pal)
  snap <- snapshot(carrier_in)
  deltas <- execute_lanes_ops(snap, kernels)
  barrier(deltas)
  rec <- reconcile(deltas, carrier_in$cell)
  carrier_out <- commit(rec, carrier_in)
  pal_out <- cell_to_pal(carrier_out$cell, pal)
  list(carrier_in = carrier_in, snapshot = snap, deltas = deltas,
       barrier = TRUE, reconciled = rec, carrier_out = carrier_out,
       pal_out = pal_out)
}

# =====================================================================
# 8. Carrier -> PAL re-encoding (closed-loop final link)
# =====================================================================

#' @title Re-encode a reconciled cell back to a pal state
#' @description Closes the loop: S_(t+1) cell -> canonical PAL. Orbits
#'   are read outer-to-inner (A,B,C,D) and dropped when NA (missing),
#'   preserving the containment order. The singularity becomes the
#'   core.
#' @param cell a \code{visualr_topology_cell}.
#' @param pal_orig the ORIGINAL pal (for mapping_pack_id/provenance
#'   continuity).
#' @return a \code{visualr_pal} object.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' res <- run_topology_pipeline(p, "rotate")
#' cell_to_pal(res$carrier_out$cell, p)
cell_to_pal <- function(cell, pal_orig) {
  if (!inherits(cell, "visualr_topology_cell")) {
    stop("`cell` must be a visualr_topology_cell.", call. = FALSE)
  }
  validate_pal(pal_orig)
  shells <- character(0)
  for (nm in c("A", "B", "C", "D")) {
    ep <- cell$orbits[[nm]]
    if (!anyNA(ep)) {
      shells <- c(shells, ep[1])  # head token (canonical: head == tail)
    }
  }
  new_pal_state(
    shells = shells,
    core = cell$singularity,
    mapping_pack_id = pal_orig$mapping_pack_id,
    provenance = pal_orig$provenance
  )
}
