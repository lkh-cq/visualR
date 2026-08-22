# == Phase 2: Central Router ABI (v0.7.0) ============================
# Status: new module, built ONLY against the frozen shared contracts in
#   R/router_contract.R (one writer per cell — this file never defines a
#   shared type; it consumes new_router_snapshot / new_routing_plan /
#   router_envelope / validate_router_plan).
#
# Role (ROUTER_CONTRACT_v070.md §3, Phase 2 ABI):
#   route_emergence / new_router_policy / get_router_policy / validate_router_plan
#   [consumes {envelope list, Snapshot, Policy} -> RoutingPlan]
#
# Semantic blindness (A2 / P1): the Router reads ONLY the routing envelope
#   (router_envelope(packet)) plus structural snapshot fields (space /
#   resources / boundaries / historical). It NEVER reads a Merge payload or
#   merge_content(). A policy's only job is to propose placements and
#   adjacencies from structural data — never a semantic score.
#
# A3 / A4: the Router output is a RoutingPlan (placements + proposed edges).
#   It never produces a Merge, never a semantic score, never a prediction.

# == Module state: policy registry (many policies live in parallel) ====
# Env defined in router_contract.R (.visualR_router_policy_env). Policies
# register here; route_emergence() looks one up by name.

# -- new_router_policy ------------------------------------------------
# Register a routing policy so it may be selected by name.
#   @param name  character(1): policy id (e.g. "identity_route").
#   @param fn    function(envelopes, snapshot) -> list(placements,
#                adjacencies = list of edge named lists with
#                source_packet_id / dest_packet_id, policy_evidence = list).
#                It must be a pure function: given the same inputs it
#                returns the same result regardless of the order it is
#                called in (order-independent; see A5 / test 3).
#   @param overwrite logical: allow replacing an existing policy.
#   @return invisible(NULL).
new_router_policy <- function(name, fn, overwrite = FALSE) {
  if (!is.character(name) || length(name) != 1L || is.na(name) || !nzchar(name)) {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("`fn` must be a function.", call. = FALSE)
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  # ABI arity: fn must accept (envelopes, snapshot).
  fmls <- names(formals(fn))
  if (length(fmls) < 2L && !("..." %in% fmls)) {
    stop("Router policy ABI: fn must accept (envelopes, snapshot).", call. = FALSE)
  }
  if (!overwrite && exists(name, envir = .visualR_router_policy_env, inherits = FALSE)) {
    stop(sprintf("Router policy '%s' already registered (fail closed); use overwrite=TRUE.",
                 name), call. = FALSE)
  }
  .visualR_router_policy_env[[name]] <- fn
  invisible(NULL)
}

# -- get_router_policy ------------------------------------------------
# Look up a policy by name; fail closed if absent.
get_router_policy <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name) || !nzchar(name)) {
    stop("`name` must be a single non-empty policy name.", call. = FALSE)
  }
  fn <- .visualR_router_policy_env[[name]]
  if (is.null(fn)) {
    stop(sprintf("Unknown router policy: '%s'. Registered: %s",
                 name, paste(sort(ls(.visualR_router_policy_env)), collapse = ", ")),
         call. = FALSE)
  }
  fn
}

# -- internal: build the routing plan from a policy result ------------
# Normalize the policy's return into a RoutingPlan, guaranteeing the Route
# Plan contains NO semantic fields (A4) by construction.
.build_routing_plan <- function(envelopes, result, route_trace) {
  if (is.null(result) || !is.list(result)) {
    stop("Router policy must return a list (fail closed).", call. = FALSE)
  }
  placements <- result$placements
  adjacencies <- result$adjacencies
  policy_evidence <- result$policy_evidence
  if (is.null(placements)) placements <- list()
  if (is.null(adjacencies)) adjacencies <- list()
  if (is.null(policy_evidence)) policy_evidence <- list()

  plan <- new_routing_plan(
    placements      = placements,
    adjacencies     = adjacencies,
    route_trace     = route_trace,
    collisions      = if (is.null(result$collisions)) list() else result$collisions,
    unresolved      = if (is.null(result$unresolved)) character(0L) else result$unresolved,
    policy_evidence = policy_evidence
  )
  # carry the policy's reported residual capacity, if any (contract 1.9);
  # absent => full input (no consumption tracked).
  if (!is.null(result$resource_left)) {
    plan$resource_left <- result$resource_left
  }
  # A4 gate: a RoutingPlan must never leak semantic fields.
  validate_router_plan(plan)
  plan
}

# -- route_emergence --------------------------------------------------
# The single Router entry point. Reads ONLY envelopes + structural snapshot,
# fires the selected policy, and returns a validated RoutingPlan.
route_emergence <- function(packets, snapshot, policy = "identity_route") {
  if (!is.list(packets)) {
    stop("`packets` must be a list of visualr_emergence_packet (fail closed).",
         call. = FALSE)
  }
  if (!inherits(snapshot, "visualr_router_snapshot")) {
    stop("`snapshot` must be a visualr_router_snapshot (A5).", call. = FALSE)
  }
  if (!is.character(policy) || length(policy) != 1L || is.na(policy) || !nzchar(policy)) {
    stop("`policy` must be a single non-empty policy name.", call. = FALSE)
  }

  # Semantic blindness: the Router works on envelope objects only.
  envelopes <- lapply(packets, function(p) {
    if (!inherits(p, "visualr_emergence_packet")) {
      stop("router received a non-packet (fail closed).", call. = FALSE)
    }
    router_envelope(p)   # envelope ONLY; never reaches the Merge payload
  })

  fn <- get_router_policy(policy)
  # The policy reads ONLY (envelopes, snapshot structural fields).
  result <- tryCatch(fn(envelopes, snapshot), error = function(e) {
    stop(sprintf("Router policy '%s' failed: %s", policy, conditionMessage(e)),
         call. = FALSE)
  })

  route_trace <- sprintf("policy=%s@round=%s", policy, snapshot$round)
  .build_routing_plan(envelopes, result, route_trace)
}
