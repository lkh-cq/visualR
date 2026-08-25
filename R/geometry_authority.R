# == v0.9 D1 — Geometric Adjacency Authority ========================
# Contract (DEVELOPMENT_PLAN_v0.9.0 §3 D1):
#   The geometric predicate is the ONLY source of computation
#   eligibility. Router-plan pairs are candidates; they enter Harmony
#   only after passing the predicate. A plan edge that fails the
#   predicate is a HARD error in strict mode and a recorded rejection
#   in audit mode — never a silent drop.
# Position resolution for envelopes: an envelope's source_address is its
#   position address. Callers supply a positions list mapping packet_id
#   -> PositionState. Missing mapping = fail closed (we cannot verify
#   what we cannot locate).

filter_plan_through_predicate <- function(plan_pairs, snapshot,
                                          positions, predicate) {
  if (!is.list(plan_pairs)) {
    stop("`plan_pairs` must be the adjacency list of a RoutingPlan.",
         call. = FALSE)
  }
  if (!is.function(predicate)) {
    stop("`predicate` must be an adjacency predicate.", call. = FALSE)
  }
  if (!inherits(snapshot, "visualr_router_snapshot")) {
    stop("Expected a visualr_router_snapshot.", call. = FALSE)
  }
  if (!is.list(positions)) {
    stop("`positions` must map packet_id -> visualr_position_state.",
         call. = FALSE)
  }
  # normalize positions into an env keyed by packet_id
  penv <- new.env(parent = emptyenv())
  for (ps in positions) {
    if (!inherits(ps, "visualr_position_state")) {
      stop("positions entries must be visualr_position_state objects.",
           call. = FALSE)
    }
    key <- paste(ps$address, collapse = "/")
    penv[[key]] <- ps
  }

  passed  <- list()
  rejected <- list()
  for (i in seq_along(plan_pairs)) {
    edge <- plan_pairs[[i]]
    src_id <- as.character(edge$source_packet_id)
    dst_id <- as.character(edge$dest_packet_id)

    src_env <- .lookup_envelope(snapshot, src_id)
    dst_env <- .lookup_envelope(snapshot, dst_id)
    src_key <- paste(src_env$source_address, collapse = "/")
    dst_key <- paste(dst_env$source_address, collapse = "/")

    src_ps <- penv[[src_key]]
    dst_ps <- penv[[dst_key]]
    if (is.null(src_ps) || is.null(dst_ps)) {
      stop(sprintf(
        paste0("Edge %d (%s -> %s): no PositionState for address '%s' ",
               "or '%s' (cannot verify eligibility — fail closed)."),
        i, src_id, dst_id, src_key, dst_key), call. = FALSE)
    }

    lt <- if (!is.null(edge$logical_time)) edge$logical_time else 0L
    ok <- isTRUE(predicate(src_ps, dst_ps, lt))
    record <- list(index = i, source_packet_id = src_id,
                   dest_packet_id = dst_id, left_pos = src_ps,
                   right_pos = dst_ps, logical_time = lt,
                   geometrically_adjacent = ok)
    if (ok) passed[[length(passed) + 1L]] <- record else
            rejected[[length(rejected) + 1L]] <- record
  }
  structure(list(passed = passed, rejected = rejected),
            class = "visualr_geometry_filtered_plan")
}

.lookup_envelope <- function(snapshot, packet_id) {
  for (e in snapshot$packets) {
    if (identical(e$packet_id, packet_id)) return(e)
  }
  stop(sprintf("packet '%s' not in snapshot (fail closed).", packet_id),
       call. = FALSE)
}

# Strict gate: any rejected edge stops computation (fail closed).
assert_no_rejected_edges <- function(filtered) {
  if (!inherits(filtered, "visualr_geometry_filtered_plan")) {
    stop("Expected a visualr_geometry_filtered_plan.", call. = FALSE)
  }
  n <- length(filtered$rejected)
  if (n > 0L) {
    details <- paste(vapply(filtered$rejected, function(r)
      sprintf("%s->%s", r$source_packet_id, r$dest_packet_id), character(1)),
      collapse = ", ")
    stop(sprintf(paste0("%d Router-plan edge(s) failed the geometric ",
                        "predicate (no geometric adjacency, no ",
                        "computation): %s"), n, details), call. = FALSE)
  }
  invisible(TRUE)
}