# == Phase 6+7: Emergence Round orchestrator + loop (v0.7.0) =========
# Status: new module, the INTEGRATION phase. Wires Phases 1-5 into one
#   atomic ComputationRound and resolves the packet_id<->Merge seam
#   (flagged between Phase 4 adjacency and Phase 5 harmony). Phase 7 runs
#   the multi-round loop and reports STRUCTURAL topology observability.
#
# Round (ROUTER_CONTRACT_v070.md §12 / §1.10):
#   LocalState_t -> Local Merge -> Emergence Packet -> Freeze Snapshot ->
#   Central Router -> Routing Plan -> Adjacency Materialization -> Harmony ->
#   New Merge -> Atomic Commit -> State_t+1
#
# Seam note (critical): materialize_adjacency() (Phase 4) returns pairs whose
#   left_merge/right_merge are the ROUTER-READABLE packet_id (character), because
#   adjacency may only read the envelope surface (A2). But harmony_step() (Phase 5)
#   needs the actual Merge objects to read content. Therefore the round resolves
#   every pair's packet_id back to its packet payload Merge BEFORE calling Harmony.
#   This is the one place both sides of the contract meet.

# == internal: packet_id -> Merge object lookup ----------------------
.packet_merge_map <- function(packets) {
  m <- new.env(parent = emptyenv())
  for (p in packets) {
    if (!inherits(p, "visualr_emergence_packet")) {
      stop("round received a non-packet (fail closed).", call. = FALSE)
    }
    pid <- p$envelope$packet_id
    if (is.null(pid) || !nzchar(pid)) {
      stop("packet with no id in round (fail closed).", call. = FALSE)
    }
    if (exists(pid, envir = m, inherits = FALSE)) {
      stop(sprintf("duplicate packet_id '%s' in round (fail closed).", pid),
           call. = FALSE)
    }
    m[[pid]] <- p$payload    # the opaque Merge
  }
  m
}

# == internal: resolve a materialized pair into a Harmony-ready pair -
.resolve_pair_merges <- function(pair, pmap) {
  left  <- if (inherits(pair$left_merge, "visualr_merge")) pair$left_merge
           else pmap[[as.character(pair$left_merge)]]
  right <- if (inherits(pair$right_merge, "visualr_merge")) pair$right_merge
           else pmap[[as.character(pair$right_merge)]]
  if (is.null(left) || is.null(right)) {
    stop("AdjacencyPair references a packet_id with no Merge in the round (fail closed).",
         call. = FALSE)
  }
  new_adjacency_pair(left_merge = left, right_merge = right,
                     left_address = pair$left_address,
                     right_address = pair$right_address,
                     shared_local_space = pair$shared_local_space,
                     route_trace = pair$route_trace,
                     logical_time = pair$logical_time)
}

# == run_emergence_round ---------------------------------------------
# Execute one complete computation round. Returns a visualr_computation_round.
run_emergence_round <- function(packets, local_state, space, resources,
                                boundaries, logical_time,
                                policy = "identity_route",
                                harmony_operator = "identity",
                                historical = list()) {
  if (!is.list(packets) || length(packets) == 0L) {
    stop("round needs at least one packet (fail closed).", call. = FALSE)
  }
  pmap <- .packet_merge_map(packets)

  # Freeze Snapshot (A5): immutable per round
  snapshot <- new_router_snapshot(round = logical_time,
                                  packets = lapply(packets, function(p) p$envelope),
                                  space = space, resources = resources,
                                  boundaries = boundaries,
                                  historical = historical)

  # Central Router (Phase 2/3) -> RoutingPlan (A4)
  plan <- route_emergence(packets, snapshot, policy = policy)
  validate_router_plan(plan)

  # Adjacency Materialization (Phase 4) -> AdjacencyPairs (A3)
  pairs <- materialize_adjacency(plan, snapshot, logical_time = logical_time)

  # Harmony (Phase 5) on each pair, resolving the id<->Merge seam
  events <- list()
  for (i in seq_along(pairs)) {
    hp <- .resolve_pair_merges(pairs[[i]], pmap)
    events[[length(events) + 1L]] <- harmony_step(hp, operator = harmony_operator)
  }

  # Atomically Commit (A5) -> MergeResult
  new_merges <- lapply(events, function(ev) ev$result)
  # residual capacity: use the policy's reported resource_left if the policy
  # tracked consumption (resource_route); otherwise the raw input (contract 1.9).
  res_left <- plan$resource_left
  if (is.null(res_left)) res_left <- resources
  result <- new_merge_result(
    new_merges     = new_merges,
    adjacency_used = pairs,
    dropped        = plan$unresolved,
    resource_left  = res_left,
    trace          = plan$route_trace
  )

  new_computation_round(snapshot = snapshot, plan = plan, pairs = pairs,
                        events = events, result = result)
}

# == internal: next-state re-packing ---------------------------------
# Assign each surviving new Merge a DISTINCT position for the next round
# (round-robin over space, deterministic). The raw result Merge's address is
# the shared_local_space of its producing pair — that would collapse many
# locals onto one cell (A6 "position is state" requires distinct positions for
# distinct entities), so the loop re-places them deterministically.
.prepare_next_state <- function(new_merges, space, resources, boundaries,
                                logical_time) {
  if (!is.null(space) && length(space) > 0L) {
    lapply(seq_along(new_merges), function(i) {
      mg <- new_merges[[i]]
      # rotate over space so each surviving merge gets its own position
      idx <- ((i - 1L) %% length(space)) + 1L
      addr <- space[[idx]]
      pack_emergence(mg, as.character(addr), "open")
    })
  } else {
    lapply(new_merges, function(mg) pack_emergence(mg, paste0("/pos", mg$merge_id), "open"))
  }
}

# == run_emergence_system --------------------------------------------
# Run several rounds, reporting structural topology observability each round.
# No intelligence/reasoning/AGI score (contract §13 forbid) — facts only.
run_emergence_system <- function(initial_merges, rounds = 3L, space,
                                 resources, boundaries,
                                 policy = "identity_route",
                                 harmony_operator = "identity") {
  if (!is.list(initial_merges) || length(initial_merges) == 0L) {
    stop("system needs at least one initial Merge (fail closed).", call. = FALSE)
  }
  if (!is.numeric(rounds) || length(rounds) != 1L || rounds < 1L) {
    stop("`rounds` must be a single integer >= 1 (fail closed).", call. = FALSE)
  }

  packets <- lapply(seq_along(initial_merges), function(i) {
    mg <- initial_merges[[i]]
    addr <- if (!is.null(mg$address) && length(mg$address) == 1L) mg$address else space[[1L]]
    pack_emergence(mg, as.character(addr), "open")
  })

  rounds_report <- list()
  for (t in seq_len(as.integer(rounds))) {
    # geometric shrink: identity pairing halves packets each round (n -> n/2).
    # When the surviving set is empty there is nothing left to compute — break
    # and return the completed system rather than crashing (P1 fix).
    if (length(packets) == 0L) {
      break
    }
    round_obj <- run_emergence_round(packets, local_state = initial_merges,
                                     space = space, resources = resources,
                                     boundaries = boundaries,
                                     logical_time = t,
                                     policy = policy,
                                     harmony_operator = harmony_operator)
    rounds_report[[t]] <- round_obj
    packets <- .prepare_next_state(round_obj$result$new_merges,
                                   space, resources, boundaries, t)
  }

  structure(
    list(
      rounds        = rounds_report,
      observability = .observe_system(rounds_report)
    ),
    class = "visualr_emergence_system"
  )
}

# == internal: structural topology observability (facts only) --------
.observe_system <- function(rounds_report) {
  rd <- lapply(rounds_report, function(r) r$result)
  list(
    layers           = length(rd),
    merge_output     = vapply(rd, function(r) length(r$new_merges), integer(1L)),
    adjacency_count  = vapply(rounds_report, function(r) length(r$pairs), integer(1L)),
    collisions_total = sum(vapply(rounds_report, function(r) length(r$plan$collisions), integer(1L))),
    unresolved_total = sum(vapply(rounds_report, function(r) length(r$plan$unresolved), integer(1L))),
    resource_left    = lapply(rd, function(r) r$resource_left),
    merge_diversity  = length(unique(unlist(lapply(rd, function(r)
      vapply(r$new_merges, function(m) m$merge_id, character(1L))))))
  )
}

# == internal: pack the round's new merges back to packets ------------
.pack_result_merges <- function(result, space) {
  .prepare_next_state(result$new_merges, space, NULL, NULL, 1L)
}

#' @export
print.visualr_emergence_system <- function(x, ...) {
  obs <- x$observability
  cat(sprintf("<visualr_emergence_system> layers=%d merges=%s adj=%s\n",
              obs$layers, paste(obs$merge_output, collapse = ","),
              paste(obs$adjacency_count, collapse = ",")))
  cat(sprintf("  diversity=%d collisions=%d unresolved=%d\n",
              obs$merge_diversity, obs$collisions_total, obs$unresolved_total))
  invisible(x)
}
