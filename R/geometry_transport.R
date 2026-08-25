# == v0.8 Transport — transmit_step & TransportedState ==============
# Math anchor (report Step 4): transport moves a positioned state along a
#   path under a metric + transport law + regulation. It does NOT create a
#   new Merge identity. Only Harmony creates fresh Merges.
# Fail-closed rules:
#   - payload (opaque content) is never mutated by transport
#   - regulation may only annotate the trace, never touch content

new_transported_state <- function(merge_obj, position, path, signature,
                                  regulation_trace = list()) {
  if (!inherits(merge_obj, "visualr_merge")) {
    stop("`merge_obj` must be a visualr_merge.", call. = FALSE)
  }
  validate_position_state(position)
  if (!inherits(path, "visualr_transmission_path")) {
    stop("`path` must be a visualr_transmission_path.", call. = FALSE)
  }
  if (!is.list(signature)) stop("`signature` must be a list.", call. = FALSE)
  structure(
    list(
      merge_id        = merge_obj$merge_id,
      merge           = merge_obj,
      position        = position,
      path            = path,
      signature       = signature,
      regulation_trace = regulation_trace
    ),
    class = "visualr_transported_state"
  )
}

transmit_step <- function(merge_obj, from, to, metric_name,
                          transport_law_name, logical_time,
                          regulation = NULL) {
  if (!inherits(merge_obj, "visualr_merge")) {
    stop("`merge_obj` must be a visualr_merge.", call. = FALSE)
  }
  validate_position_state(from)
  validate_position_state(to)

  d_fn <- get_metric(metric_name)
  dist <- d_fn(from, to)
  if (!is.numeric(dist) || length(dist) != 1L || is.na(dist) || dist < 0) {
    stop("metric must return one non-negative finite distance (fail closed).",
         call. = FALSE)
  }

  # build/extend the immutable path
  path <- new_transmission_path(merge_obj$merge_id, from)
  path <- append_transmission_step(
    path, from, to,
    grade    = "T1",
    logical_time = logical_time,
    regulation_event = regulation
  )

  # apply the transport law to the STATE (not the payload):
  t_fn <- get_transport_law(transport_law_name)
  transported <- t_fn(list(position = to), from, to, regulation)
  if (is.null(transported$position)) {
    stop("transport law returned no $position (fail closed).", call. = FALSE)
  }

  new_transported_state(
    merge_obj       = merge_obj,
    position        = transported$position,
    path            = path,
    signature       = transmission_signature(path),
    regulation_trace = list(regulation = regulation, distance = dist)
  )
}