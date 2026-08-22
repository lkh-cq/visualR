# == Phase 4: Adjacency Materialization (v0.7.0) ======================
# Status: new module, built ONLY against the frozen contracts in
#   R/router_contract.R (one writer per cell — this file never touches
#   a shared type's definition; it only constructs via the contract
#   helpers new_adjacency_pair / new_routing_plan / new_router_snapshot).
#
# Role (ROUTER_CONTRACT_v070.md §3, Phase 4 ABI):
#   materialize_adjacency / validate_adjacency   [RoutingPlan -> AdjacencyPair]
#
# Thesis (A3): "no adjacency, no computation". A RoutingPlan proposes
#   edges; the ONLY legal Harmony input is a typed visualr_adjacency_pair.
#   This module turns a plan's proposed edges into those pairs, and it
#   FAILS CLOSED on anything structurally malformed.
#
# Semantic blindness (A2 / P1): this module may read ONLY the structural
#   fields of the plan ($adjacencies / $placements / $route_trace) and of
#   the snapshot ($space / $boundaries / $resources). It never reads a
#   Merge payload / merge_content(). The merge identity carried into a
#   pair is the router-readable envelope packet_id (the routing-level
#   handle the plan's edges already refer to).

# -- internal helper: read one named field off an adjacency edge ---------
# An edge is a named list or a named atomic vector carrying
#   source_packet_id / dest_packet_id (see validate_adjacency).
# Returns the field value, or NULL when the field (or the name layer)
#   is absent. Never throws here — validation happens upstream.
.adj_edge_field <- function(edge, field) {
  nm <- names(edge)
  if (is.null(nm)) {
    return(NULL)
  }
  if (!(field %in% nm)) {
    return(NULL)
  }
  edge[[field]]
}

# -- internal helper: is an address a legal, open, addressable cell? ------
# Structural legality only (position is state, A6): the address must be a
#   known cell of the snapshot's boundary registry and be open. This is the
#   "two ends are adjacent / legal" check materialize performs. It reads
#   ONLY snapshot$boundaries — never merge semantics.
.adj_legal_address <- function(addr, boundaries) {
  if (is.null(addr) || length(addr) != 1L) {
    return(FALSE)
  }
  if (is.null(boundaries) || length(boundaries) == 0L) {
    return(FALSE)
  }
  nm <- names(boundaries)
  if (is.null(nm) || !(addr %in% nm)) {
    return(FALSE)
  }
  identical(unname(boundaries[[addr]]), "open")
}

# == validate_adjacency: plan-side structural gate (A3) =================
# Checks ONLY that plan$adjacencies is a structurally legal list of
#   proposed edges (each edge is a named container with a non-empty
#   source_packet_id and a non-empty dest_packet_id). It does NOT touch the
#   snapshot and does NOT read any packet/merge semantics. An empty edge
#   list is legal (no adjacency this round => nothing to compute); any
#   malformed edge fails closed.
validate_adjacency <- function(plan) {
  if (!inherits(plan, "visualr_routing_plan")) {
    stop("Expected a visualr_routing_plan; only these may be materialized (A3).",
         call. = FALSE)
  }
  adj <- plan$adjacencies
  if (is.null(adj)) {
    stop("Routing plan has no $adjacencies field (fail closed).", call. = FALSE)
  }
  if (!is.list(adj)) {
    stop("plan$adjacencies must be a list (fail closed).", call. = FALSE)
  }
  if (length(adj) == 0L) {
    return(TRUE)   # no adjacency -> nothing to compute, A3-consistent
  }
  for (i in seq_along(adj)) {
    edge <- adj[[i]]
    src <- .adj_edge_field(edge, "source_packet_id")
    dst <- .adj_edge_field(edge, "dest_packet_id")
    if (is.null(src) || length(src) != 1L || is.na(src) || src == "") {
      stop(sprintf("Adjacency edge %d has no valid non-empty source_packet_id (fail closed).",
                   i), call. = FALSE)
    }
    if (is.null(dst) || length(dst) != 1L || is.na(dst) || dst == "") {
      stop(sprintf("Adjacency edge %d has no valid non-empty dest_packet_id (fail closed).",
                   i), call. = FALSE)
    }
    if (identical(as.character(src), as.character(dst))) {
      stop(sprintf("Adjacency edge %d is self-referential (source == dest) (fail closed).",
                   i), call. = FALSE)
    }
  }
  TRUE
}

# -- internal: resolve the assigned address of a packet ----------------
# The Router's placement (plan$placements) is authoritative: a policy may have
# moved a packet to a NEW cell (nearest_valid_route / resource_route). Using
# only the envelope source_address would silently ignore the placement (and
# crash when the source cell is closed). Address is structural (A6), never
# semantic.
.adj_packet_address <- function(packet_id, placements, env) {
  # 1) from placements if present
  if (!is.null(placements) && length(placements) > 0L) {
    for (pl in placements) {
      if (identical(as.character(pl$packet_id), as.character(packet_id))) {
        return(pl$address)
      }
    }
  }
  # 2) fall back to envelope source_address (placement was identity/no-move)
  env$source_address
}

# == materialize_adjacency: RoutingPlan -> list<AdjacencyPair> ==========
# Reads ONLY structural fields:
#   plan$adjacencies, plan$route_trace          (plan side)
#   snapshot$packets (envelopes), snapshot$space,
#   snapshot$boundaries, snapshot$resources     (snapshot side)
#   logical_time (argument)
# Never reads a Merge payload / merge_content().
#
# For every proposed edge:
#   * resolve each packet_id against the snapshot's envelopes (fail closed
#     if a referenced packet does not exist);
#   * left/right addresses come from the matched envelope source_address
#     (position is state, A6);
#   * both ends must be distinct, legal, open cells (fail closed otherwise);
#   * shared_local_space comes from snapshot$space once co-residency of the
#     two ends is established.
# Returns a list of visualr_adjacency_pair — the ONLY legal Harmony input.
materialize_adjacency <- function(plan, snapshot, logical_time) {
  validate_adjacency(plan)

  if (!inherits(snapshot, "visualr_router_snapshot")) {
    stop("Expected a visualr_router_snapshot; materialization needs the round state (A5).",
         call. = FALSE)
  }
  if (!is.numeric(logical_time) || length(logical_time) != 1L) {
    stop("`logical_time` must be a single integer round tag.", call. = FALSE)
  }

  # -- snapshot structural fields required for legality ------------------
  boundaries <- snapshot$boundaries
  space      <- snapshot$space
  if (is.null(boundaries) || length(boundaries) == 0L) {
    stop("Snapshot carries no $boundaries registry; cannot verify adjacency (fail closed).",
         call. = FALSE)
  }
  if (is.null(space) || length(space) == 0L) {
    stop("Snapshot carries no $space; cannot determine shared local space (fail closed).",
         call. = FALSE)
  }

  # -- build packet_id -> envelope lookup (router-readable surface only) -
  envs <- snapshot$packets
  if (is.null(envs) || !is.list(envs)) {
    stop("Snapshot has no $packets list (fail closed).", call. = FALSE)
  }
  lookup <- new.env(parent = emptyenv())
  for (e in envs) {
    if (!inherits(e, "visualr_routing_envelope")) {
      stop("snapshot$packets must hold visualr_routing_envelope objects (fail closed).",
           call. = FALSE)
    }
    if (is.null(e$packet_id) || !nzchar(e$packet_id)) {
      stop("Envelope in snapshot has no packet_id (fail closed).", call. = FALSE)
    }
    if (exists(e$packet_id, envir = lookup, inherits = FALSE)) {
      stop(sprintf("Duplicate packet_id '%s' in snapshot (fail closed).",
                   e$packet_id), call. = FALSE)
    }
    lookup[[e$packet_id]] <- e
  }

  route_trace <- plan$route_trace
  if (is.null(route_trace)) {
    route_trace <- character(0L)
  }

  adj <- plan$adjacencies
  pairs <- vector("list", length(adj))
  if (length(adj) > 0L) {
    for (i in seq_along(adj)) {
      edge <- adj[[i]]
      src_id <- as.character(.adj_edge_field(edge, "source_packet_id"))
      dst_id <- as.character(.adj_edge_field(edge, "dest_packet_id"))

      src_env <- lookup[[src_id]]
      dst_env <- lookup[[dst_id]]
      if (is.null(src_env)) {
        stop(sprintf("Adjacency edge %d references nonexistent source packet '%s' (fail closed).",
                     i, src_id), call. = FALSE)
      }
      if (is.null(dst_env)) {
        stop(sprintf("Adjacency edge %d references nonexistent dest packet '%s' (fail closed).",
                     i, dst_id), call. = FALSE)
      }

      # Address is resolved from the Router's placement (plan$placements),
      # falling back to the envelope source_address. This respects policies
      # that move a packet to a NEW cell (nearest_valid_route / resource_route)
      # and avoids crashing when the source cell is closed.
      left_address  <- .adj_packet_address(src_id, plan$placements, src_env)
      right_address <- .adj_packet_address(dst_id, plan$placements, dst_env)

      if (is.null(left_address) || is.null(right_address)) {
        stop(sprintf("Adjacency edge %d: a packet lacks source_address (fail closed).",
                     i), call. = FALSE)
      }
      if (identical(as.character(left_address), as.character(right_address))) {
        stop(sprintf("Adjacency edge %d is self-adjacency (same address both ends, A6) (fail closed).",
                     i), call. = FALSE)
      }

      # two ends must be legal, open, distinct cells of this space
      if (!.adj_legal_address(left_address, boundaries)) {
        stop(sprintf("Adjacency edge %d: left address '%s' is not an open legal cell (fail closed).",
                     i, left_address), call. = FALSE)
      }
      if (!.adj_legal_address(right_address, boundaries)) {
        stop(sprintf("Adjacency edge %d: right address '%s' is not an open legal cell (fail closed).",
                     i, right_address), call. = FALSE)
      }

      # -- construct the pair (contract helper; no merge semantics read) --
      pairs[[i]] <- new_adjacency_pair(
        left_merge         = as.character(src_env$packet_id),
        right_merge        = as.character(dst_env$packet_id),
        left_address       = as.character(left_address),
        right_address      = as.character(right_address),
        shared_local_space = as.character(space[[1L]]),
        route_trace        = route_trace,
        logical_time       = as.integer(logical_time)
      )
    }
  }

  pairs
}
