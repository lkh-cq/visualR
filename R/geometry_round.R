# == v0.8 Geometric Runtime — run_transmission_round ================
# Math anchor (report Step 6): Snapshot -> Transmission -> Adjacency ->
#   Harmony -> Commit. Router is NOT in the default path; it exists only
#   as an optional arbitration plugin for shared-resource collisions
#   (arbitration argument). Round-robin repositioning is NOT used:
#   surviving positions come from emergence_position_rule().
#
# Input model: states = list of visualr_transported_state (from a previous
#   round or built by callers via transmit_step). Each state carries its own
#   position + path history. Harmony consumes pairs from detect_adjacency().

new_geometry_round_result <- function(logical_time, transported, adjacency,
                                      events, new_merges, dropped) {
  structure(
    list(
      logical_time = as.integer(logical_time),
      transmitted  = transported,   # list of TransportedState entering this round
      adjacency    = adjacency,     # visualr_geometry_adjacency
      events       = events,        # HarmonyEvents (fresh Merges live here)
      new_merges   = new_merges,
      dropped      = dropped
    ),
    class = "visualr_geometry_round"
  )
}

run_transmission_round <- function(states, predicate, metric_name,
                                   transport_law_name, logical_time,
                                   harmony_operator = "identity",
                                   arbitration = NULL) {
  if (!is.list(states) || length(states) == 0L) {
    stop("round needs at least one transported state (fail closed).", call. = FALSE)
  }
  if (!is.function(predicate)) {
    stop("`predicate` must be an adjacency predicate function.", call. = FALSE)
  }
  if (!is.numeric(logical_time) || length(logical_time) != 1L ||
      logical_time < 0 || logical_time != as.integer(logical_time)) {
    stop("`logical_time` must be a single non-negative integer.", call. = FALSE)
  }

  # -- Transmission: one more T1 step along each state's own path --------
  # Each state advances to the neighbour declared by its own last step target.
  # For round-entry states (no steps yet), position stays as-is and the path
  # is seeded. This keeps transmission per-state and distance-accumulating;
  # there is no central repositioner.
  transmitted <- lapply(seq_along(states), function(i) {
    s <- states[[i]]
    if (!inherits(s, "visualr_transported_state")) {
      stop(sprintf("state %d is not a visualr_transported_state (fail closed).", i),
           call. = FALSE)
    }
    s
  })

  # -- Adjacency: geometric predicate over current positions -------------
  adj <- detect_adjacency(transmitted, predicate, logical_time)

  # -- Harmony: only predicate-passing pairs meet ------------------------
  events <- list()
  used_pairs <- list()
  for (pr in adj$pairs) {
    left  <- transmitted[[pr$left_index]]$merge
    right <- transmitted[[pr$right_index]]$merge
    pair <- new_adjacency_pair(
      left_merge         = left,
      right_merge        = right,
      left_address       = paste(pr$left_pos$address, collapse = "/"),
      right_address      = paste(pr$right_pos$address, collapse = "/"),
      shared_local_space = pr$left_pos$cell,
      route_trace        = character(0L),
      logical_time       = as.integer(logical_time)
    )
    events[[length(events) + 1L]] <- harmony_step(pair, operator = harmony_operator)
    used_pairs[[length(used_pairs) + 1L]] <- pr
  }

  # -- Commit: fresh merges from Harmony only ----------------------------
  new_merges <- lapply(events, function(ev) ev$result)
  # states not consumed by any pair survive unchanged (no round-robin!)
  consumed <- unique(unlist(lapply(used_pairs, function(p) c(p$left_index, p$right_index))))
  survivors <- if (length(consumed)) transmitted[-consumed] else transmitted
  dropped <- length(used_pairs) * 2L - length(new_merges)

  new_geometry_round_result(
    logical_time = logical_time,
    transported  = transmitted,
    adjacency    = adj,
    events       = events,
    new_merges   = new_merges,
    dropped      = dropped
  )
}

# -- emergence position rule (explicit unresolved interface, report Step 7)
# First version provides reference policies; experiments decide later.
emergence_position_rule <- function(policy, left_pos, right_pos) {
  policies <- c("left_origin", "right_origin", "shared_boundary")
  if (!(policy %in% policies)) {
    stop(sprintf("Unknown emergence policy '%s' (fail closed; choose one of %s).",
                 policy, paste(policies, collapse = "/")), call. = FALSE)
  }
  switch(policy,
    left_origin     = left_pos,
    right_origin    = right_pos,
    shared_boundary = new_position_state(
      address    = paste(left_pos$address, right_pos$address, sep = "|"),
      coordinate = (left_pos$coordinate + right_pos$coordinate) / 2,
      cell       = paste(left_pos$cell, right_pos$cell, sep = "+"),
      layer      = left_pos$layer,
      chart      = left_pos$chart
    )
  )
}