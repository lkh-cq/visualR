# == v0.10 Graded Transmission — TransmissionEvent layer ============
# Report contract (deep-research-report 4, "T0-T4 formal freeze"):
#   grade classification is DERIVED from the geometric facts of the move,
#   never caller-supplied. Priority chain (first match wins):
#     layer/chart transition      -> T4
#     cell/boundary crossing      -> T3
#     >1 elementary edge          -> T2
#     exactly 1 elementary edge   -> T1
#     no positional change        -> T0
#
# A T0 event still advances logical_time and may carry phase/regulation
# deltas — "waiting/regulation" is a first-class transmission fact.
#
# Identity invariant (inherited from v0.8): transport NEVER creates a new
# Merge identity. The event layer stores a merge handle reference only.

classify_grade <- function(from_position, to_positions, boundary_flags = NULL) {
  if (!inherits(from_position, "visualr_position_state")) {
    stop("`from_position` must be a visualr_position_state.", call. = FALSE)
  }
  if (!is.list(to_positions)) {
    stop("`to_positions` must be a list of visualr_position_state.",
         call. = FALSE)
  }
  for (p in to_positions) validate_position_state(p)
  n <- length(to_positions)

  # T0: no movement at all
  if (n == 0L) return("T0")

  # identical endpoint = no movement even if a target was supplied
  addr_eq <- function(a, b) {
    identical(paste(a$address, collapse = "/"),
              paste(b$address, collapse = "/")) &&
      identical(a$chart, b$chart) && identical(a$layer, b$layer)
  }
  if (n == 1L && addr_eq(from_position, to_positions[[1L]])) return("T0")

  # priority 1: any layer/chart transition -> T4
  for (p in to_positions) {
    if (!identical(p$layer, from_position$layer) ||
        !identical(p$chart, from_position$chart)) return("T4")
  }

  # priority 2: cell/boundary crossing -> T3
  crossed <- !is.null(boundary_flags) && any(vapply(boundary_flags,
                                                    isTRUE, logical(1)))
  if (crossed) return("T3")
  for (p in to_positions) {
    if (!identical(p$cell, from_position$cell)) return("T3")
  }

  # priority 3: multiple elementary edges -> T2 ; single -> T1
  if (n >= 2L) return("T2")
  "T1"
}

new_transmission_event <- function(merge_id, from_position, to_positions,
                                   boundary_flags = NULL, logical_time,
                                   phase_delta = 0, regulation_delta = NULL) {
  if (!is.character(merge_id) || length(merge_id) != 1L || !nzchar(merge_id)) {
    stop("`merge_id` must be a single non-empty character.", call. = FALSE)
  }
  validate_position_state(from_position)
  if (!is.numeric(logical_time) || length(logical_time) != 1L ||
      logical_time < 0 || logical_time != as.integer(logical_time)) {
    stop("`logical_time` must be a single non-negative integer.", call. = FALSE)
  }
  if (!is.numeric(phase_delta) || length(phase_delta) != 1L) {
    stop("`phase_delta` must be a single number.", call. = FALSE)
  }
  grade <- classify_grade(from_position, to_positions, boundary_flags)

  n <- length(to_positions)
  steps <- list()
  if (grade != "T0") {
    for (i in seq_len(n)) {
      steps[[length(steps) + 1L]] <- list(
        from         = from_position,
        to           = to_positions[[i]],
        boundary     = if (!is.null(boundary_flags)) isTRUE(boundary_flags[[i]]) else FALSE,
        index        = i
      )
    }
  } else {
    steps[[1L]] <- list(
      from     = from_position,
      to       = from_position,   # T0: position unchanged by definition
      boundary = FALSE,
      index    = 1L
    )
  }

  structure(
    list(
      merge_id        = merge_id,
      grade           = grade,
      from            = from_position,
      to_positions    = to_positions,
      boundary_flags  = boundary_flags,
      n_substeps      = if (grade == "T0") 0L else as.integer(n),
      phase_delta     = phase_delta,
      regulation_delta = regulation_delta,
      logical_time    = as.integer(logical_time),
      substeps        = steps
    ),
    class = "visualr_transmission_event"
  )
}

validate_transmission_event <- function(ev) {
  if (!inherits(ev, "visualr_transmission_event")) {
    stop("Expected a visualr_transmission_event.", call. = FALSE)
  }
  expected <- classify_grade(ev$from, ev$to_positions, ev$boundary_flags)
  if (!identical(ev$grade, expected)) {
    stop(sprintf("event grade '%s' does not match geometric facts ('%s') ",
                 "(fail closed).", ev$grade, expected), call. = FALSE)
  }
  invisible(TRUE)
}

# T0 completeness: a T0 event changes time/phase/regulation but NOT position.
event_is_position_invariant <- function(ev) {
  validate_transmission_event(ev)
  identical(ev$grade, "T0")
}