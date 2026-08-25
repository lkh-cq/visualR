# == v0.8 Path Base — TransmissionPath =============================
# Math anchor: gamma = (p_0, p_1, ..., p_k); path participates in the
#   result. Append-only by construction; no mutation API exists.

new_transmission_path <- function(merge_id, start_position) {
  validate_position_state(start_position)
  structure(
    list(
      merge_id  = merge_id,
      positions = list(start_position),
      steps     = list()
    ),
    class = "visualr_transmission_path"
  )
}

append_transmission_step <- function(path, from, to, grade,
                                     logical_time,
                                     boundary_event = NULL,
                                     regulation_event = NULL) {
  if (!inherits(path, "visualr_transmission_path")) {
    stop("Expected a visualr_transmission_path.", call. = FALSE)
  }
  validate_position_state(from); validate_position_state(to)
  if (!identical(path$positions[[length(path$positions)]], from)) {
    stop("Step `from` does not match current path head (immutable history, ",
         "fail closed).", call. = FALSE)
  }
  grades <- c("T1", "T2", "T3", "T4")
  if (!is.character(grade) || length(grade) != 1L || !(grade %in% grades)) {
    stop("`grade` must be one of T1/T2/T3/T4.", call. = FALSE)
  }
  if (!is.numeric(logical_time) || length(logical_time) != 1L ||
      logical_time != as.integer(logical_time) || logical_time < 0) {
    stop("`logical_time` must be a single non-negative integer.", call. = FALSE)
  }
  step <- list(
    from             = from,
    to               = to,
    grade            = grade,
    logical_time     = as.integer(logical_time),
    boundary_event   = boundary_event,
    regulation_event = regulation_event
  )
  out <- structure(
    list(
      merge_id  = path$merge_id,
      positions = c(path$positions, list(to)),
      steps     = c(path$steps, list(step))
    ),
    class = "visualr_transmission_path"
  )
  out
}

path_length_steps <- function(path) length(path$steps)

# Equality: same endpoint AND same full history => equal. Two paths with
# identical endpoints but different steps compare unequal (the future
# promotion gate same_endpoint_different_path_is_not_same_state).
paths_equal <- function(p1, p2) {
  identical(p1$positions, p2$positions) && identical(p1$steps, p2$steps)
}

# TransmissionSignature: lossy summary (distance/grade/time counts).
# Contract: signature equality does NOT imply transport-result equality
#   (holonomy warning); it is an audit digest only.
transmission_signature <- function(path) {
  grades <- vapply(path$steps, function(s) s$grade, character(1))
  times  <- vapply(path$steps, function(s) s$logical_time, numeric(1))
  list(
    merge_id     = path$merge_id,
    n_steps      = length(path$steps),
    grade_counts = table(factor(grades, levels = c("T1","T2","T3","T4"))),
    t_start      = if (length(times)) min(times) else NA_integer_,
    t_end        = if (length(times)) max(times) else NA_integer_
  )
}