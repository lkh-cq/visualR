# == Phase 3: Router Baseline Policies (v0.7.0) ======================
# Status: new module. These are TOY baselines, NOT intelligent algorithms.
#   Their purpose (ROUTER_CONTRACT_v070.md §9) is to confirm the Router ABI
#   itself holds: when the policy is swapped, the rest of the system keeps
#   the same semantic contract. Therefore: Router ABI is ABOVE Routing
#   Policy. Each policy is a pure function fn(envelopes, snapshot) ->
#   list(placements, adjacencies, policy_evidence, ...) where each edge is
#   a named list: list(source_packet_id=, dest_packet_id=) — the exact
#   schema validate_adjacency()/materialize_adjacency() (Phase 4) expect.
#
# Semantic blindness (A2): a policy reads ONLY envelope structural fields
#   (packet_id / source_address / logical_time / boundary) and snapshot
#   structural fields (space / resources / boundaries / historical). It
#   never reads a Merge payload / merge_content(). No semantic score.
#
# The v0.7.0 frozen adjacency arity is 1<->1 (Q3). Therefore every policy
#   returns a MATCHING (disjoint pairing) of packets. Odd leftovers go to
#   "unresolved". A "1<->1" pairing is exactly the minimal primitive.

# -- internal: helper to pair indices deterministically (order-independent)
# Split a set of packet ids into disjoint ordered pairs. Returns a list with
#   $adjacencies  (pairs) and $unresolved (odd leftover packet ids). The
#   pairing depends ONLY on the keys, not on call order, so a policy is
#   order-independent. An odd leftover is surfaced to $unresolved (contract
#   no-hidden-aggregation, gate-11) — never silently dropped.
.pair_indices <- function(keys) {
  n <- length(keys)
  adjacencies <- list()
  unresolved <- character(0L)
  if (n >= 2L) {
    ord <- order(keys, method = "radix")
    keep <- ord[seq_len(n %/% 2L) * 2L - 1L]
    mate <- ord[seq_len(n %/% 2L) * 2L]
    adjacencies <- Map(function(i, j) list(source_packet_id = keys[[i]],
                                           dest_packet_id   = keys[[j]]),
                       keep, mate)
    if (n %% 2L == 1L) {
      leftover <- ord[n]
      unresolved <- keys[[leftover]]
    }
  } else if (n == 1L) {
    unresolved <- keys[[1L]]
  }
  list(adjacencies = adjacencies, unresolved = unresolved)
}

# -- policy 1: identity_route -----------------------------------------
# Keeps every packet at its own address (no move). Adjacency = deterministic
# pairing in packet_id order (a "1<->1" matching). The edge references the
# packets by packet_id (the router-readable handle materialize_adjacency
# resolves against snapshot$packets envelope$packet_id).
identity_route <- function(envelopes, snapshot) {
  pids <- vapply(envelopes, function(e) as.character(e$packet_id), character(1L))
  placements <- Map(function(e) list(packet_id = e$packet_id, address = e$source_address),
                    envelopes)
  pr <- .pair_indices(pids)
  list(placements = placements, adjacencies = pr$adjacencies,
       unresolved = pr$unresolved,
       policy_evidence = list(policy = "identity_route"))
}

# -- policy 2: nearest_valid_route ------------------------------------
# Place each packet at the nearest OPEN cell of the snapshot boundaries
# registry (structural legality only, A6 position-is-state). Adjacency =
# matching by the assigned cell so co-resident cells pair.
nearest_valid_route <- function(envelopes, snapshot) {
  boundaries <- snapshot$boundaries
  open_cells <- names(boundaries)[vapply(boundaries, function(b) identical(unname(b), "open"),
                                         logical(1L))]
  if (length(open_cells) == 0L) {
    return(list(placements = list(), adjacencies = list(),
                unresolved = vapply(envelopes, function(e) e$packet_id, character(1L)),
                policy_evidence = list(policy = "nearest_valid_route", note = "no open cells")))
  }
  # deterministic nearest: robust to non-numeric cell addresses (position is
  # state, A6; address is a string token). Assign each packet the nearest OPEN
  # cell in ONE deterministic pass over the radix-sorted packet order, using an
  # exclusive free-cell iterator so no two packets share a cell and the 1<->1
  # matching stays collision-free.
  open_sorted <- sort(open_cells, method = "radix")
  # free-cell iterator (round-robin over open cells)
  free_cells <- open_sorted
  next_cell <- 1L
  take_free_cell <- function() {
    cell <- free_cells[[next_cell]]
    next_cell <<- next_cell + 1L
    if (next_cell > length(free_cells)) next_cell <<- 1L
    cell
  }
  # deterministic packet order (by packet_id) so the pass is order-independent
  ord <- order(vapply(envelopes, function(e) as.character(e$packet_id), character(1L)),
               method = "radix")
  assignments <- lapply(ord, function(i) {
    e <- envelopes[[i]]
    addr <- as.character(e$source_address)
    at <- match(addr, open_sorted)
    pick <- if (is.na(at)) {
      take_free_cell()
    } else {
      open_sorted[[which.min(abs(at - seq_along(open_sorted)))]]
    }
    list(packet_id = e$packet_id, address = pick)
  })
  # dedup: any cell claimed twice gets bumped to the next free cell
  seen <- new.env(parent = emptyenv())
  assignments <- lapply(assignments, function(a) {
    if (exists(a$address, envir = seen, inherits = FALSE)) {
      a$address <- take_free_cell()
    }
    seen[[a$address]] <- TRUE
    a
  })
  pids <- vapply(assignments, function(a) as.character(a$packet_id), character(1L))
  pr <- .pair_indices(pids)
  list(placements = assignments, adjacencies = pr$adjacencies,
       unresolved = pr$unresolved,
       policy_evidence = list(policy = "nearest_valid_route"))
}

# -- policy 3: phase_route --------------------------------------------
# Group packets by logical_time (phase) and pair WITHIN each phase. Reflects
# Q4's "adjacency lifetime = one logical round" default: packets born in the
# same round are adjacent; packets from different rounds are NOT paired.
phase_route <- function(envelopes, snapshot) {
  # stable phase key per envelope
  phase <- vapply(envelopes, function(e) as.character(e$logical_time), character(1L))
  pid <- vapply(envelopes, function(e) as.character(e$packet_id), character(1L))
  placements <- Map(function(e) list(packet_id = e$packet_id, address = e$source_address),
                    envelopes)
  # pair within each phase group
  adjacencies <- list()
  unresolved <- character(0L)
  for (ph in unique(phase)) {
    group_pids <- pid[phase == ph]
    pr <- .pair_indices(group_pids)
    adjacencies <- c(adjacencies, pr$adjacencies)
    unresolved <- c(unresolved, pr$unresolved)
  }
  list(placements = placements, adjacencies = adjacencies,
       unresolved = unresolved,
       policy_evidence = list(policy = "phase_route"))
}

# -- policy 4: resource_route -----------------------------------------
# Water-fill: place packets into cells by residual capacity WITHOUT
# exceeding snapshot$resources (greedy, deterministic). Collision when a
# cell is desired by more than the allowed bound.
resource_route <- function(envelopes, snapshot) {
  res <- snapshot$resources
  if (is.null(res) || length(res) == 0L) {
    return(list(placements = list(), adjacencies = list(),
                unresolved = vapply(envelopes, function(e) e$packet_id, character(1L)),
                policy_evidence = list(policy = "resource_route", note = "no resources")))
  }
  cells <- names(res)
  cap <- if (is.null(names(res))) rep(1L, length(res)) else as.numeric(res)
  names(cap) <- cells
  placements <- list()
  collisions <- list()
  unresolved <- character(0L)
  for (e in envelopes) {
    pid <- as.character(e$packet_id)
    # deterministic: first open cell with residual capacity
    open <- cells[cap > 0]
    if (length(open) == 0L) {
      unresolved <- c(unresolved, pid)
      next
    }
    pick <- open[1L]
    cap[[pick]] <- cap[[pick]] - 1
    placements[[length(placements) + 1L]] <- list(packet_id = pid, address = pick)
  }
  # pair placed packets; surface any odd leftover as unresolved (gate-11)
  pids <- vapply(placements, function(a) as.character(a$packet_id), character(1L))
  pr <- .pair_indices(pids)
  unresolved <- c(unresolved, pr$unresolved)
  # residual capacity after consumption (contract 1.9, not the raw input)
  list(placements = placements, adjacencies = pr$adjacencies,
       collisions = collisions, unresolved = unresolved,
       resource_left = cap,
       policy_evidence = list(policy = "resource_route"))
}

# -- policy 5: deterministic_shuffle_route ----------------------------
# Reproducible shuffle (seed = snapshot$round), then pair. Proves that
# "random-looking" ordering in a policy is still order-independent/deterministic
# as long as it is a pure function of the round key.
deterministic_shuffle_route <- function(envelopes, snapshot) {
  round <- snapshot$round
  set.seed(if (is.numeric(as.integer(round)) && length(as.integer(round)) == 1L) as.integer(round) else 1L)
  pids <- vapply(envelopes, function(e) as.character(e$packet_id), character(1L))
  # reproducible shuffle of packet_id (seed = round), then pair
  perm <- sample(pids)
  pr <- .pair_indices(perm)
  placements <- Map(function(e) list(packet_id = e$packet_id, address = e$source_address),
                    envelopes)
  list(placements = placements, adjacencies = pr$adjacencies,
       unresolved = pr$unresolved,
       policy_evidence = list(policy = "deterministic_shuffle_route", seed = round))
}

# -- policy 6: random_reference_route ---------------------------------
# Reproducible random reference routing (seeded by round), pairing into
# the reference space. Also order-independent (pure function of round).
random_reference_route <- function(envelopes, snapshot) {
  round <- snapshot$round
  set.seed(if (is.numeric(as.integer(round)) && length(as.integer(round)) == 1L) as.integer(round) else 1L)
  pids <- vapply(envelopes, function(e) as.character(e$packet_id), character(1L))
  # reproducible random reference routing (seeded by round): pair by a
  # deterministic permutation of packet_id
  perm <- sample(pids)
  pr <- .pair_indices(perm)
  placements <- Map(function(e) list(packet_id = e$packet_id, address = e$source_address),
                    envelopes)
  list(placements = placements, adjacencies = pr$adjacencies,
       unresolved = pr$unresolved,
       policy_evidence = list(policy = "random_reference_route", seed = round))
}

# -- register all baseline policies -----------------------------------
# Called at package load so the six are always available in the registry.
register_baseline_router_policies <- function(overwrite = TRUE) {
  tbl <- list(
    identity_route            = identity_route,
    nearest_valid_route       = nearest_valid_route,
    phase_route               = phase_route,
    resource_route            = resource_route,
    deterministic_shuffle_route = deterministic_shuffle_route,
    random_reference_route    = random_reference_route
  )
  for (nm in names(tbl)) {
    new_router_policy(nm, tbl[[nm]], overwrite = overwrite)
  }
  invisible(NULL)
}
