# == v0.8 Arbitration — shared-resource collision plugin ============
# Report contract: regulation/arbitration must NOT choose meaning for a
# Merge; it only decides WHO enters a contested cell this tick, by a
# deterministic, semantic-blind rule. The loser stays at its own position
# with its path intact (no deletion — deferral).
# Semantic blindness: arbitration reads ONLY positions/ids, never content.

# Detect collisions: two or more states declaring the same target cell.
# Target = each state's declared next position cell (from its last step's
# `to`, i.e. current $position). States grouped by (cell, chart, layer).
detect_cell_collisions <- function(states) {
  if (!is.list(states)) {
    stop("`states` must be a list of visualr_transported_state.", call. = FALSE)
  }
  key_of <- function(s) paste(s$position$cell, s$position$chart,
                              s$position$layer, sep = "::")
  groups <- list()
  for (i in seq_along(states)) {
    s <- states[[i]]
    if (!inherits(s, "visualr_transported_state")) {
      stop(sprintf("state %d is not a visualr_transported_state (fail closed).", i),
           call. = FALSE)
    }
    k <- key_of(s)
    groups[[k]] <- c(groups[[k]], i)
  }
  # keep only contested cells (>=2 states)
  groups[vapply(groups, function(g) length(g) >= 2L, logical(1))]
}

# Deterministic tie-break chain (semantic-blind):
#   1) shorter accumulated path (fewer steps wins — closer to origin)
#   2) lexicographically smaller merge_id (total order, reproducible)
arbitrate_collisions <- function(states, collisions) {
  if (!is.list(collisions)) {
    stop("`collisions` must come from detect_cell_collisions().", call. = FALSE)
  }
  winners <- list(); losers <- list()
  for (k in names(collisions)) {
    idx <- collisions[[k]]
    ord <- order(
      vapply(states[idx], function(s) path_length_steps(s$path), numeric(1)),
      vapply(states[idx], function(s) s$merge_id, character(1))
    )
    ranked <- idx[ord]
    winners[[k]] <- ranked[1L]
    losers[[k]]  <- if (length(ranked) > 1L) ranked[-1L] else list()
  }
  list(winners = winners, losers = losers)
}

# Apply: winner keeps position; losers are deferred — their position is
# rewound to their PREVIOUS step's `to` (path history preserved, immutable:
# we rebuild the state with the shorter path prefix, never mutate).
apply_arbitration <- function(states, arb) {
  deferred_idx <- unique(unlist(arb$losers))
  if (!length(deferred_idx)) return(list(states = states, deferred = integer(0)))
  out <- states
  for (i in deferred_idx) {
    s <- states[[i]]
    n <- path_length_steps(s$path)
    if (n >= 2L) {
      prev_pos <- s$path$positions[[n]]          # n steps => n+1 positions; index n is the previous position
      short_path <- .path_prefix(s$path, n)      # keep first n positions => first n-1 steps
      rewound <- new_transported_state(
        merge_obj        = s$merge,
        position         = prev_pos,
        path             = short_path,
        signature        = transmission_signature(short_path),
        regulation_trace = list(deferred_from = s$position, reason = "cell_collision")
      )
      out[[i]] <- rewound
    }
    # n == 1: no earlier position to rewind to -> stay as-is (deferral in place)
  }
  list(states = out, deferred = deferred_idx)
}

# internal: prefix of an immutable path (first k positions/steps kept)
.path_prefix <- function(path, k) {
  structure(
    list(
      merge_id  = path$merge_id,
      positions = path$positions[seq_len(k)],
      steps     = if (k >= 1L) path$steps[seq_len(k - 1L)] else list()
    ),
    class = "visualr_transmission_path"
  )
}