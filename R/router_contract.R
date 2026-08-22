# == Router Contract Base — shared object constructors (v0.7.0) =====
# Status: FROZEN contract base. This file is the SINGLE writer of the
#   shared objects (per ownership matrix, one writer per cell). New
#   phase modules READ these types; they never redefine them.
# Types (from inst/ROUTER_CONTRACT_v070.md §1):
#   LocalState / Merge / EmergencePacket / RoutingEnvelope /
#   RouterSnapshot / RoutingPlan / AdjacencyPair / HarmonyEvent /
#   MergeResult / ComputationRound
#
# Semantics:
#   - Merge$content is OPAQUE (A2): stored behind a private closure env,
#     exposed only via accessor functions, never to router code path.
#   - AdjacencyPair is the ONLY legal Harmony input (A3): harmony() must
#     type-check class == "visualr_adjacency_pair".
#   - Position is state, not annotation (A6): distinct address => distinct
#     entity even when content matches.

# == Registry environments (module state) ==========================
# Router policies and harmony operators register here so many plugins can
# live in parallel without touching the contracts.
.visualR_router_policy_env <- new.env(parent = emptyenv())
.visualR_harmony_op_env <- new.env(parent = emptyenv())

# Internal: opaque carrier for Merge$content (A2 privacy envelope).
# The content is stored inside the function environment; only the explicit
# accessor functions can read it; the router path (router_envelope) never
# reaches here.
merge_opaque <- function(content, merge_id, origin_local, logical_time) {
  # Store content in a LOCKED private environment. There is NO public
  # `get_content` member and no `content` field on the Merge list, so the
  # shortcut `m$opaque$get_content()` is impossible — content is reachable
  # only through merge_content() (the Harmony/local-only accessor discipline,
  # per contract P1: "stop misreads at the object-system level, not by comment").
  # R cannot forbid reflection, but this removes the ordinary public path and
  # forces any reader through the documented accessor.
  e <- new.env(parent = emptyenv())
  e$content <- content
  lockEnvironment(e, bindings = TRUE)
  structure(list(env = e), class = "visualr_merge_opaque")
}

# internal: read the opaque content out of a locked env (only reachable via
# merge_content). Env is locked, so this is a read-only access.
.opaque_read <- function(opaque) {
  opaque$env$content
}

# -- Merge ---------------------------------------------------------
# A Merge carries opaque content. The router must only ever handle envelopes;
# access to content is limited to the accessor contract below.
new_merge <- function(content, merge_id, origin_local, logical_time) {
  if (!is.character(merge_id) || length(merge_id) != 1L || merge_id == "") {
    stop("`merge_id` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.character(origin_local) || length(origin_local) != 1L) {
    stop("`origin_local` must be a single character local id.", call. = FALSE)
  }
  if (!is.numeric(logical_time) || length(logical_time) != 1L) {
    stop("`logical_time` must be a single integer round tag.", call. = FALSE)
  }
  structure(
    list(
      merge_id = merge_id,
      opaque = merge_opaque(content, merge_id, origin_local, logical_time),
      origin_local = origin_local,
      logical_time = logical_time,
      address = NULL            # set by placement; position is state (A6)
    ),
    class = "visualr_merge"
  )
}

# Accessor for semantic content. ONLY Harmony/local may call this; it is
# deliberately NOT reachable from the router envelope path. The content lives
# in a locked private env, so it is reachable only through this accessor.
merge_content <- function(m) {
  if (!inherits(m, "visualr_merge")) {
    if (is.character(m) && length(m) == 1L) {
      stop("merge_content() received a packet_id string. Resolve the pair's ",
           "packet_id to its Merge via run_emergence_round/.resolve_pair_merges ",
           "before Harmony (contract 4.1).", call. = FALSE)
    }
    stop("merge_content() expects a visualr_merge, not ",
         paste(class(m), collapse = "/"), call. = FALSE)
  }
  .opaque_read(m$opaque)
}

# -- RoutingEnvelope ------------------------------------------------
# The ONLY thing a Router may read. Built by pack_emergence().
new_routing_envelope <- function(packet_id, source_local, source_address,
                                 logical_time, boundary,
                                 transport = list(), integrity = character(0L)) {
  structure(
    list(
      packet_id     = packet_id,
      source_local  = source_local,
      source_address= source_address,
      logical_time  = logical_time,
      boundary      = boundary,
      transport     = transport,
      integrity     = integrity
    ),
    class = "visualr_routing_envelope"
  )
}

# -- EmergencePacket -----------------------------------------------
# Two layers: envelope (router-readable) + payload (opaque Merge).
new_emergence_packet <- function(envelope, merge_obj) {
  stopifnot(inherits(envelope, "visualr_routing_envelope"))
  stopifnot(inherits(merge_obj, "visualr_merge"))
  structure(
    list(envelope = envelope, payload = merge_obj),
    class = "visualr_emergence_packet"
  )
}

# -- Router accessor: envelope ONLY (semantic blindness, A2/P1) -----
# The router code path MUST use router_envelope() and MUST NOT reach
# packet$payload / merge_content(). This is the enforcement seam.
router_envelope <- function(packet) {
  stopifnot(inherits(packet, "visualr_emergence_packet"))
  packet$envelope
}

# Guard: concurrency check for a packet having no route feedback path.
validate_emergence_packet <- function(packet) {
  if (!inherits(packet, "visualr_emergence_packet")) {
    stop("Expected a visualr_emergence_packet.", call. = FALSE)
  }
  envl <- packet$envelope
  if (is.null(envl$packet_id) || envl$packet_id == "") {
    stop("Packet has no packet_id (fail closed).", call. = FALSE)
  }
  if (is.null(envl$source_address) || length(envl$source_address) == 0L) {
    stop("Packet has no source_address (fail closed).", call. = FALSE)
  }
  TRUE
}

# -- RouterSnapshot (immutable per round, A5) -----------------------
# Static snapshot: no mutations until end-of-round commit.
new_router_snapshot <- function(round, packets, space, resources,
                                boundaries, historical = list()) {
  structure(
    list(
      round      = round,
      packets    = packets,       # list of envelopes, order-independent
      space      = space,
      resources  = resources,
      boundaries = boundaries,
      historical = historical
    ),
    class = "visualr_router_snapshot"
  )
}

# -- RoutingPlan (router output — NO semantics, A4) -----------------
new_routing_plan <- function(placements = list(), adjacencies = list(),
                             route_trace = character(0L), collisions = list(),
                             unresolved = character(0L), policy_evidence = list()) {
  structure(
    list(
      placements      = placements,
      adjacencies     = adjacencies,
      route_trace     = route_trace,
      collisions      = collisions,
      unresolved      = unresolved,
      policy_evidence = policy_evidence
    ),
    class = "visualr_routing_plan"
  )
}

# -- AdjacencyPair (the ONLY legal Harmony input, A3) ---------------
new_adjacency_pair <- function(left_merge, right_merge, left_address,
                               right_address, shared_local_space,
                               route_trace, logical_time) {
  structure(
    list(
      left_merge          = left_merge,
      right_merge         = right_merge,
      left_address        = left_address,
      right_address       = right_address,
      shared_local_space  = shared_local_space,
      route_trace         = route_trace,
      logical_time        = logical_time
    ),
    class = "visualr_adjacency_pair"
  )
}

# -- HarmonyEvent (what H emits) ------------------------------------
new_harmony_event <- function(pair, operator_id, result, trace = character(0L)) {
  structure(
    list(
      pair         = pair,
      operator_id  = operator_id,
      result       = result,
      trace        = trace
    ),
    class = "visualr_harmony_event"
  )
}

# -- MergeResult (result of a full round) ---------------------------
new_merge_result <- function(new_merges = list(), adjacency_used = list(),
                             dropped = character(0L), resource_left = numeric(0L),
                             trace = character(0L)) {
  structure(
    list(
      new_merges     = new_merges,
      adjacency_used = adjacency_used,
      dropped        = dropped,
      resource_left  = resource_left,
      trace          = trace
    ),
    class = "visualr_merge_result"
  )
}

# -- ComputationRound (atomic unit) ---------------------------------
new_computation_round <- function(snapshot, plan, pairs, events, result) {
  structure(
    list(
      snapshot = snapshot,
      plan     = plan,
      pairs    = pairs,
      events   = events,
      result   = result
    ),
    class = "visualr_computation_round"
  )
}

# -- Validators (fail-closed, gate tests need these) ----------------
# Recursively scan a structure for forbidden semantic field names (A4); a
# semantic score hidden inside a nested placement/edge/evidence must be caught.
.has_forbidden_semantic <- function(x, forbidden) {
  if (is.list(x) && !is.null(names(x))) {
    if (any(names(x) %in% forbidden)) return(TRUE)
    for (el in x) {
      if (.has_forbidden_semantic(el, forbidden)) return(TRUE)
    }
  } else if (is.atomic(x) && length(x) == 1L && is.character(x)) {
    # also catch a bare forbidden token sent as a scalar value
    if (x %in% forbidden) return(TRUE)
  }
  FALSE
}

validate_router_plan <- function(plan) {
  if (!inherits(plan, "visualr_routing_plan")) {
    stop("Expected a visualr_routing_plan.", call. = FALSE)
  }
  forbidden <- c("semantic_score", "meaning", "prediction", "classification",
                 "new_merge", "score")
  # A4: scan recursively so a semantic field hidden in placements / edges /
  # policy_evidence cannot pass silently.
  present <- if (.has_forbidden_semantic(plan, forbidden)) forbidden else character(0L)
  if (length(present) > 0L) {
    stop("Routing plan leaks semantic fields: ", paste(present, collapse = ", "),
         " (A4 violation, recursive scan).", call. = FALSE)
  }
  TRUE
}

validate_adjacency_pair <- function(pair) {
  if (!inherits(pair, "visualr_adjacency_pair")) {
    stop("Expected a visualr_adjacency_pair; only these may enter Harmony (A3).",
         call. = FALSE)
  }
  if (is.null(pair$left_merge) || is.null(pair$right_merge)) {
    stop("Adjacency pair missing a side (fail closed).", call. = FALSE)
  }
  TRUE
}

validate_harmony_event <- function(ev) {
  if (!inherits(ev, "visualr_harmony_event")) {
    stop("Expected a visualr_harmony_event.", call. = FALSE)
  }
  if (!inherits(ev$result, "visualr_merge")) {
    stop("HarmonyEvent must produce a Merge (M_ij').", call. = FALSE)
  }
  TRUE
}

# Printers (S3 methods for readable CLI rendering)
print.visualr_routing_envelope <- function(x, ...) {
  cat(sprintf("<RoutingEnvelope> id=%s from=%s@%s t=%s boundary=%s\n",
              x$packet_id, x$source_local, x$source_address,
              x$logical_time, x$boundary))
  invisible(x)
}
print.visualr_merge <- function(x, ...) {
  cat(sprintf("<Merge> id=%s origin=%s t=%s addr=%s (content opaque)\n",
              x$merge_id, x$origin_local, x$logical_time,
              if (is.null(x$address)) "NA" else x$address))
  invisible(x)
}
print.visualr_router_snapshot <- function(x, ...) {
  cat(sprintf("<RouterSnapshot> round=%s packets=%d\n",
              x$round, length(x$packets)))
  invisible(x)
}
print.visualr_routing_plan <- function(x, ...) {
  cat(sprintf("<RoutingPlan> placements=%d adjacencies=%d unresolved=%d\n",
              length(x$placements), length(x$adjacencies), length(x$unresolved)))
  invisible(x)
}
print.visualr_adjacency_pair <- function(x, ...) {
  cat(sprintf("<AdjacencyPair> %s@%s <-> %s@%s space=%s\n",
              x$left_merge, x$left_address, x$right_merge, x$right_address,
              x$shared_local_space))
  invisible(x)
}




