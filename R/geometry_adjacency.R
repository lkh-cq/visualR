# == v0.8 Adjacency Predicate ======================================
# Math anchor (report Step 5): A_t(i,j) = 1[C_space AND C_distance AND
#   C_distinct]. Only pairs passing the predicate become AdjacencyPair
#   candidates. This is GEOMETRIC adjacency, independent of Router plans.
# Semantic blindness: predicate reads ONLY positions (addresses/
#   coordinates/cell/layer/chart) — never merge content (A2).

default_adjacency_predicate <- function(max_distance = 1, metric_name = "manhattan",
                                        same_layer_only = TRUE) {
  if (!is.numeric(max_distance) || length(max_distance) != 1L ||
      is.na(max_distance) || max_distance < 0) {
    stop("`max_distance` must be one non-negative number.", call. = FALSE)
  }
  force(metric_name); force(same_layer_only)
  function(pi_, pj_, logical_time) {
    if (!inherits(pi_, "visualr_position_state") ||
        !inherits(pj_, "visualr_position_state")) {
      stop("predicate needs two visualr_position_state objects.", call. = FALSE)
    }
    # C_distinct: different addresses
    a1 <- paste(pi_$address, collapse = "/")
    a2 <- paste(pj_$address, collapse = "/")
    if (identical(a1, a2)) return(FALSE)
    # C_layer
    if (same_layer_only && !identical(pi_$layer, pj_$layer)) return(FALSE)
    # C_space: same chart required for coordinate comparison (chart change
    # needs an explicit transition contract — out of scope this batch)
    if (!identical(pi_$chart, pj_$chart)) return(FALSE)
    # C_distance under registered metric
    d_fn <- get_metric(metric_name)
    d <- d_fn(pi_, pj_)
    isTRUE(d <= max_distance)
  }
}

detect_adjacency <- function(states, predicate, logical_time) {
  if (!is.list(states)) {
    stop("`states` must be a list of visualr_transported_state or ",
         "visualr_position_state.", call. = FALSE)
  }
  pos <- lapply(seq_along(states), function(i) {
    s <- states[[i]]
    if (inherits(s, "visualr_transported_state")) s$position else s
  })
  for (p in pos) validate_position_state(p)
  n <- length(pos)
  pairs <- list()
  if (n >= 2L) {
    for (i in seq_len(n - 1L)) {
      for (j in seq(i + 1L, n)) {
        if (isTRUE(predicate(pos[[i]], pos[[j]], logical_time))) {
          pairs[[length(pairs) + 1L]] <- list(
            left_index  = i,
            right_index = j,
            left_pos    = pos[[i]],
            right_pos   = pos[[j]],
            logical_time = logical_time
          )
        }
      }
    }
  }
  structure(
    list(pairs = pairs, n_states = n, logical_time = as.integer(logical_time)),
    class = "visualr_geometry_adjacency"
  )
}