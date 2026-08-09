# == Distributed residual reservoir runtime ==========================
# Experimental mainline (2026-08-09).
#
# A reservoir owns residual supply at positioned nodes. Multiple local
# pipes read one immutable snapshot, request distributed positions, and
# receive a joint allocation subject to BOTH pipe budgets and node draw
# limits. Position relations survive the extraction as an explicit
# topology object.
#
# The router never interprets a signal. It only manages addresses,
# budgets, node supply, collisions, and the atomic commit. This keeps
# local meaning outside the routing centre.

.visualr_golden_step <- (sqrt(5) - 1) / 2

assert_finite_numeric <- function(x, name, allow_empty = FALSE) {
  if (!is.numeric(x) || (!allow_empty && length(x) == 0L) ||
      anyNA(x) || any(!is.finite(x))) {
    stop(sprintf("`%s` must contain finite numeric values.", name),
         call. = FALSE)
  }
  invisible(TRUE)
}

normalise_positions <- function(position) {
  out <- position
  for (j in seq_len(ncol(out))) {
    lo <- min(out[, j])
    hi <- max(out[, j])
    if (isTRUE(all.equal(lo, hi))) {
      out[, j] <- 0.5
    } else {
      out[, j] <- (out[, j] - lo) / (hi - lo)
    }
  }
  out
}

#' @title Create a positioned residual reservoir
#' @description Builds the shared residual field sampled by concurrent
#'   local pipes. Signal values and extractable supply are deliberately
#'   separate: a node may carry any finite numeric signal while supply
#'   and per-step capacity remain non-negative resource quantities.
#' @param signal finite numeric vector, one value per node.
#' @param position numeric matrix with one row per node. Defaults to a
#'   one-dimensional ordered field.
#' @param supply non-negative residual supply per node. Defaults to one.
#' @param capacity non-negative per-step draw limit per node. Defaults
#'   to the initial supply.
#' @param node_id unique non-empty node identifiers.
#' @param metadata arbitrary list retained with the field.
#' @return object of class \code{visualr_reservoir}.
#' @examples
#' field <- new_reservoir(
#'   signal = c(2, -1, 4, 3),
#'   position = cbind(x = c(0, 0.3, 0.7, 1)),
#'   supply = c(1, 1, 1, 1), capacity = rep(0.6, 4)
#' )
new_reservoir <- function(signal, position = NULL, supply = NULL,
                          capacity = NULL, node_id = NULL,
                          metadata = list()) {
  assert_finite_numeric(signal, "signal")
  n <- length(signal)

  if (is.null(position)) {
    position <- matrix(if (n == 1L) 0.5 else seq(0, 1, length.out = n),
                       ncol = 1L, dimnames = list(NULL, "x1"))
  }
  if (is.data.frame(position)) position <- as.matrix(position)
  if (!is.matrix(position) || !is.numeric(position) || nrow(position) != n ||
      ncol(position) < 1L || anyNA(position) || any(!is.finite(position))) {
    stop("`position` must be a finite numeric matrix with one row per node.",
         call. = FALSE)
  }
  if (is.null(colnames(position))) {
    colnames(position) <- paste0("x", seq_len(ncol(position)))
  }

  if (is.null(supply)) supply <- rep(1, n)
  assert_finite_numeric(supply, "supply")
  if (length(supply) != n || any(supply < 0)) {
    stop("`supply` must be non-negative and match `signal`.", call. = FALSE)
  }

  if (is.null(capacity)) capacity <- supply
  assert_finite_numeric(capacity, "capacity")
  if (length(capacity) != n || any(capacity < 0)) {
    stop("`capacity` must be non-negative and match `signal`.",
         call. = FALSE)
  }

  if (is.null(node_id)) node_id <- paste0("n", seq_len(n))
  if (!is.character(node_id) || length(node_id) != n || anyNA(node_id) ||
      any(node_id == "") || anyDuplicated(node_id)) {
    stop("`node_id` must contain unique, non-empty identifiers.",
         call. = FALSE)
  }
  if (!is.list(metadata)) stop("`metadata` must be a list.", call. = FALSE)

  rownames(position) <- node_id
  structure(
    list(node_id = node_id, signal = as.numeric(signal),
         position = position, supply = as.numeric(supply),
         capacity = as.numeric(capacity), tick = 0L,
         metadata = metadata, trace = list()),
    class = "visualr_reservoir"
  )
}

#' @export
print.visualr_reservoir <- function(x, ...) {
  cat(sprintf("<visualr_reservoir> nodes=%d dimensions=%d tick=%d\n",
              length(x$node_id), ncol(x$position), x$tick))
  cat(sprintf("  supply=%.6g | per-step available=%.6g\n",
              sum(x$supply), sum(pmin(x$supply, x$capacity))))
  invisible(x)
}

#' @title Create a local sampling pipe
#' @description A pipe exposes only routing information: identifier,
#'   draw budget, phase, phase step, and spatial bandwidth. Its internal
#'   interpretation of sampled signals is intentionally outside the
#'   reservoir router.
#' @param id one non-empty identifier.
#' @param budget positive draw budget per step.
#' @param phase finite scalar or vector in any real range; stored modulo
#'   one.
#' @param phase_step finite scalar or vector. Irrational steps provide a
#'   non-periodic schedule in the ideal continuous system, but are a
#'   policy choice rather than a reservoir invariant.
#' @param bandwidth positive spatial bandwidth in normalised position.
#' @param metadata arbitrary local metadata hidden from route scoring.
#' @return object of class \code{visualr_reservoir_pipe}.
#' @examples
#' p <- new_reservoir_pipe("local-a", budget = 0.8,
#'                         phase_step = sqrt(2) - 1)
new_reservoir_pipe <- function(id, budget, phase = 0,
                               phase_step = sqrt(2) - 1,
                               bandwidth = 0.2, metadata = list()) {
  if (!is.character(id) || length(id) != 1L || is.na(id) || id == "") {
    stop("`id` must be one non-empty character value.", call. = FALSE)
  }
  assert_finite_numeric(budget, "budget")
  if (length(budget) != 1L || budget <= 0) {
    stop("`budget` must be one positive value.", call. = FALSE)
  }
  assert_finite_numeric(phase, "phase")
  assert_finite_numeric(phase_step, "phase_step")
  if (!(length(phase) %in% c(1L, length(phase_step))) &&
      !(length(phase_step) %in% c(1L, length(phase)))) {
    stop("`phase` and `phase_step` must be scalar or have compatible lengths.",
         call. = FALSE)
  }
  assert_finite_numeric(bandwidth, "bandwidth")
  if (length(bandwidth) != 1L || bandwidth <= 0) {
    stop("`bandwidth` must be one positive value.", call. = FALSE)
  }
  if (!is.list(metadata)) stop("`metadata` must be a list.", call. = FALSE)

  structure(
    list(id = id, budget = as.numeric(budget), phase = phase %% 1,
         phase_step = phase_step, bandwidth = as.numeric(bandwidth),
         metadata = metadata),
    class = "visualr_reservoir_pipe"
  )
}

validate_pipes <- function(pipes) {
  if (inherits(pipes, "visualr_reservoir_pipe")) pipes <- list(pipes)
  if (!is.list(pipes) || length(pipes) == 0L ||
      !all(vapply(pipes, inherits, logical(1), "visualr_reservoir_pipe"))) {
    stop("`pipes` must contain visualr_reservoir_pipe objects.",
         call. = FALSE)
  }
  ids <- vapply(pipes, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("pipe ids must be unique.", call. = FALSE)
  pipes
}

#' @title Generate a modular phase sequence
#' @description Returns finite points from a modular rotation. A rational
#'   step eventually repeats in exact arithmetic; an irrational step does
#'   not. Floating-point output is an executable scheduling approximation,
#'   not a proof of irrationality.
#' @param n non-negative number of points.
#' @param seed starting phase.
#' @param step phase increment.
#' @return numeric vector in the half-open interval [0, 1).
#' @examples
#' phase_sequence(5, step = sqrt(2) - 1)
phase_sequence <- function(n, seed = 0, step = sqrt(2) - 1) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || !is.finite(n) ||
      n < 0 || n != as.integer(n)) {
    stop("`n` must be one non-negative integer.", call. = FALSE)
  }
  assert_finite_numeric(seed, "seed")
  assert_finite_numeric(step, "step")
  if (length(seed) != 1L || length(step) != 1L) {
    stop("`seed` and `step` must be scalar.", call. = FALSE)
  }
  n <- as.integer(n)
  if (n == 0L) return(numeric(0))
  (seed + (seq_len(n) - 1L) * step) %% 1
}

pipe_anchor <- function(pipe, dimensions) {
  phase <- rep_len(pipe$phase, dimensions)
  # A scalar phase is unfolded into different dimensional coordinates;
  # otherwise every pipe would move only on a diagonal line.
  offset <- if (length(pipe$phase) == 1L) {
    ((seq_len(dimensions) - 1L) * .visualr_golden_step) %% 1
  } else {
    rep(0, dimensions)
  }
  (phase + offset) %% 1
}

#' @title Advance pipe phases without sampling
#' @param pipes one pipe or a list of pipes.
#' @param steps non-negative integer number of phase steps.
#' @return list of updated pipes.
advance_pipes <- function(pipes, steps = 1L) {
  pipes <- validate_pipes(pipes)
  if (!is.numeric(steps) || length(steps) != 1L || is.na(steps) ||
      !is.finite(steps) || steps < 0 || steps != as.integer(steps)) {
    stop("`steps` must be one non-negative integer.", call. = FALSE)
  }
  lapply(pipes, function(pipe) {
    width <- max(length(pipe$phase), length(pipe$phase_step))
    pipe$phase <- (rep_len(pipe$phase, width) +
                   as.integer(steps) * rep_len(pipe$phase_step, width)) %% 1
    pipe
  })
}

#' @title Route concurrent pipes over positioned residual nodes
#' @description Produces preferences only. It never consumes supply and
#'   never interprets signal values. Each row is a local pipe and each
#'   column is a positioned reservoir node.
#' @param reservoir a \code{visualr_reservoir}.
#' @param pipes one pipe or list of pipes.
#' @param k optional positive number of nearest nodes retained per pipe;
#'   NULL leaves the spatial kernel distributed over all available nodes.
#' @return non-negative pipe-by-node preference matrix.
route_pipes <- function(reservoir, pipes, k = NULL) {
  if (!inherits(reservoir, "visualr_reservoir")) {
    stop("`reservoir` must be a visualr_reservoir.", call. = FALSE)
  }
  pipes <- validate_pipes(pipes)
  n <- length(reservoir$node_id)
  if (!is.null(k)) {
    if (!is.numeric(k) || length(k) != 1L || is.na(k) || !is.finite(k) ||
        k < 1 || k != as.integer(k)) {
      stop("`k` must be NULL or one positive integer.", call. = FALSE)
    }
    k <- min(as.integer(k), n)
  }

  pos <- normalise_positions(reservoir$position)
  available <- pmin(reservoir$supply, reservoir$capacity) > 0
  out <- matrix(0, nrow = length(pipes), ncol = n,
                dimnames = list(vapply(pipes, `[[`, character(1), "id"),
                                reservoir$node_id))
  for (i in seq_along(pipes)) {
    pipe <- pipes[[i]]
    anchor <- pipe_anchor(pipe, ncol(pos))
    delta <- abs(sweep(pos, 2L, anchor, "-"))
    # Modular distance lets phase travel across the field boundary.
    delta <- pmin(delta, 1 - delta)
    distance2 <- rowSums(delta^2)
    weight <- exp(-distance2 / (2 * pipe$bandwidth^2))
    weight[!available] <- 0
    if (!is.null(k)) {
      available_order <- order(distance2 + ifelse(available, 0, Inf),
                               seq_len(n), method = "radix")
      keep_n <- min(k, sum(available))
      keep <- if (keep_n == 0L) integer(0) else
        available_order[seq_len(keep_n)]
      weight[-keep] <- 0
    }
    # Guard numerical underflow by keeping the nearest available node.
    if (sum(weight) == 0 && any(available)) {
      nearest <- order(distance2 + ifelse(available, 0, Inf),
                       seq_len(n), method = "radix")[1L]
      weight[nearest] <- 1
    }
    out[i, ] <- weight
  }
  out
}

#' @title Jointly allocate node supply to concurrent pipes
#' @description Uses simultaneous water-filling rounds. Every proposal
#'   reads the same remaining snapshot; oversubscribed nodes scale all
#'   competing proposals by the same factor. The result is independent
#'   of pipe list order after rows are restored by id.
#' @param reservoir a \code{visualr_reservoir}.
#' @param pipes one pipe or list of pipes.
#' @param preferences optional matrix from \code{route_pipes}.
#' @param tolerance non-negative numeric stopping tolerance.
#' @param max_iter positive maximum simultaneous rounds.
#' @return object of class \code{visualr_allocation}.
allocate_pipes <- function(reservoir, pipes, preferences = NULL,
                           tolerance = 1e-10, max_iter = 1000L) {
  if (!inherits(reservoir, "visualr_reservoir")) {
    stop("`reservoir` must be a visualr_reservoir.", call. = FALSE)
  }
  pipes <- validate_pipes(pipes)
  pipe_id <- vapply(pipes, `[[`, character(1), "id")
  node_id <- reservoir$node_id
  if (is.null(preferences)) preferences <- route_pipes(reservoir, pipes)
  if (!is.matrix(preferences) || !is.numeric(preferences) ||
      !identical(dim(preferences), c(length(pipes), length(node_id))) ||
      anyNA(preferences) || any(!is.finite(preferences)) ||
      any(preferences < 0)) {
    stop("`preferences` must be a finite non-negative pipe-by-node matrix.",
         call. = FALSE)
  }
  if (!is.null(rownames(preferences))) {
    if (!setequal(rownames(preferences), pipe_id)) {
      stop("preference row names must match pipe ids.", call. = FALSE)
    }
    preferences <- preferences[pipe_id, , drop = FALSE]
  }
  if (!is.null(colnames(preferences))) {
    if (!setequal(colnames(preferences), node_id)) {
      stop("preference column names must match node ids.", call. = FALSE)
    }
    preferences <- preferences[, node_id, drop = FALSE]
  }
  dimnames(preferences) <- list(pipe_id, node_id)

  assert_finite_numeric(tolerance, "tolerance")
  if (length(tolerance) != 1L || tolerance < 0) {
    stop("`tolerance` must be one non-negative value.", call. = FALSE)
  }
  if (!is.numeric(max_iter) || length(max_iter) != 1L || is.na(max_iter) ||
      !is.finite(max_iter) || max_iter < 1 || max_iter != as.integer(max_iter)) {
    stop("`max_iter` must be one positive integer.", call. = FALSE)
  }

  budget <- vapply(pipes, `[[`, numeric(1), "budget")
  available <- pmin(reservoir$supply, reservoir$capacity)
  remaining_budget <- budget
  remaining_supply <- available
  allocation <- matrix(0, nrow = length(pipes), ncol = length(node_id),
                       dimnames = list(pipe_id, node_id))
  iterations <- 0L

  for (iteration in seq_len(as.integer(max_iter))) {
    iterations <- iteration
    active_weight <- preferences
    active_weight[remaining_budget <= tolerance, ] <- 0
    active_weight[, remaining_supply <= tolerance] <- 0
    weight_sum <- rowSums(active_weight)
    active_rows <- which(weight_sum > tolerance &
                         remaining_budget > tolerance)
    if (length(active_rows) == 0L) break

    proposal <- matrix(0, nrow = nrow(allocation), ncol = ncol(allocation),
                       dimnames = dimnames(allocation))
    proposal[active_rows, ] <-
      active_weight[active_rows, , drop = FALSE] /
      weight_sum[active_rows] * remaining_budget[active_rows]

    proposed_by_node <- colSums(proposal)
    node_scale <- rep(0, length(proposed_by_node))
    proposed <- proposed_by_node > tolerance
    node_scale[proposed] <- pmin(
      1, remaining_supply[proposed] / proposed_by_node[proposed]
    )
    accepted <- sweep(proposal, 2L, node_scale, "*")
    progress <- sum(accepted)
    if (progress <= tolerance) break

    allocation <- allocation + accepted
    remaining_budget <- pmax(0, budget - rowSums(allocation))
    remaining_supply <- pmax(0, available - colSums(allocation))
  }

  budget_used <- rowSums(allocation)
  supply_used <- colSums(allocation)
  constraint_ok <- all(budget_used <= budget + tolerance) &&
    all(supply_used <= available + tolerance)
  if (!constraint_ok) {
    stop("allocation violated a budget or node capacity (fail closed).",
         call. = FALSE)
  }
  unresolved <- remaining_budget > tolerance &
    rowSums(sweep(preferences, 2L, remaining_supply > tolerance, "*")) >
      tolerance

  structure(
    list(matrix = allocation, preferences = preferences,
         pipe_budget = budget, node_available = available,
         budget_used = budget_used,
         budget_remaining = pmax(0, budget - budget_used),
         supply_used = supply_used,
         supply_remaining = pmax(0, available - supply_used),
         iterations = iterations, converged = !any(unresolved),
         constraint_ok = constraint_ok, tolerance = tolerance),
    class = "visualr_allocation"
  )
}

#' @export
print.visualr_allocation <- function(x, ...) {
  cat(sprintf("<visualr_allocation> pipes=%d nodes=%d iterations=%d\n",
              nrow(x$matrix), ncol(x$matrix), x$iterations))
  cat(sprintf("  extracted=%.6g | constraints=%s | converged=%s\n",
              sum(x$matrix), x$constraint_ok, x$converged))
  invisible(x)
}

allocation_outputs <- function(reservoir, allocation) {
  amount <- rowSums(allocation$matrix)
  signal_sum <- rowSums(sweep(allocation$matrix, 2L,
                              reservoir$signal, "*"))
  mean_signal <- ifelse(amount > allocation$tolerance,
                        signal_sum / amount, NA_real_)
  centroid <- allocation$matrix %*% reservoir$position
  for (i in seq_along(amount)) {
    if (amount[i] > allocation$tolerance) {
      centroid[i, ] <- centroid[i, ] / amount[i]
    } else {
      centroid[i, ] <- NA_real_
    }
  }
  colnames(centroid) <- paste0("centroid_", colnames(reservoir$position))
  data.frame(pipe_id = rownames(allocation$matrix), amount = amount,
             signal_sum = signal_sum, mean_signal = mean_signal,
             centroid, row.names = NULL, check.names = FALSE)
}

#' @title Recover the topology of one concurrent extraction
#' @description Keeps selected node addresses and pairwise position
#'   relations. Values are not collapsed into a single feature vector.
#' @param reservoir a \code{visualr_reservoir}.
#' @param allocation a \code{visualr_allocation} or allocation matrix.
#' @param threshold positive support threshold.
#' @return object of class \code{visualr_sample_topology} containing
#'   nodes, edges, and per-pipe support.
reservoir_topology <- function(reservoir, allocation, threshold = 1e-12) {
  if (!inherits(reservoir, "visualr_reservoir")) {
    stop("`reservoir` must be a visualr_reservoir.", call. = FALSE)
  }
  mat <- if (inherits(allocation, "visualr_allocation")) {
    allocation$matrix
  } else {
    allocation
  }
  if (!is.matrix(mat) || !is.numeric(mat) ||
      !identical(ncol(mat), length(reservoir$node_id)) ||
      anyNA(mat) || any(!is.finite(mat)) || any(mat < 0)) {
    stop("`allocation` must be a finite non-negative pipe-by-node matrix.",
         call. = FALSE)
  }
  assert_finite_numeric(threshold, "threshold")
  if (length(threshold) != 1L || threshold <= 0) {
    stop("`threshold` must be one positive value.", call. = FALSE)
  }
  if (is.null(rownames(mat))) rownames(mat) <- paste0("p", seq_len(nrow(mat)))
  colnames(mat) <- reservoir$node_id

  total <- colSums(mat)
  selected <- which(total > threshold)
  node_pos <- reservoir$position[selected, , drop = FALSE]
  nodes <- data.frame(node_id = reservoir$node_id[selected],
                      extraction = total[selected], node_pos,
                      row.names = NULL, check.names = FALSE)

  support_index <- which(mat > threshold, arr.ind = TRUE)
  if (nrow(support_index) == 0L) {
    pipe_support <- data.frame(pipe_id = character(0), node_id = character(0),
                               amount = numeric(0))
  } else {
    pipe_support <- data.frame(
      pipe_id = rownames(mat)[support_index[, "row"]],
      node_id = reservoir$node_id[support_index[, "col"]],
      amount = mat[support_index], row.names = NULL
    )
  }

  if (length(selected) < 2L) {
    edges <- data.frame(from = character(0), to = character(0),
                        distance = numeric(0), relation = character(0),
                        shared_pipes = character(0))
  } else {
    pairs <- t(utils::combn(selected, 2L))
    delta <- reservoir$position[pairs[, 2L], , drop = FALSE] -
      reservoir$position[pairs[, 1L], , drop = FALSE]
    shared <- vapply(seq_len(nrow(pairs)), function(i) {
      ids <- rownames(mat)[mat[, pairs[i, 1L]] > threshold &
                            mat[, pairs[i, 2L]] > threshold]
      paste(ids, collapse = ",")
    }, character(1))
    relation <- ifelse(shared == "", "concurrent-support", "co-sampled")
    edges <- data.frame(
      from = reservoir$node_id[pairs[, 1L]],
      to = reservoir$node_id[pairs[, 2L]],
      distance = sqrt(rowSums(delta^2)), relation = relation,
      shared_pipes = shared, row.names = NULL, check.names = FALSE
    )
    colnames(delta) <- paste0("delta_", colnames(reservoir$position))
    edges <- cbind(edges, delta)
  }

  structure(list(nodes = nodes, edges = edges,
                 pipe_support = pipe_support),
            class = "visualr_sample_topology")
}

#' @export
print.visualr_sample_topology <- function(x, ...) {
  cat(sprintf("<visualr_sample_topology> nodes=%d edges=%d supports=%d\n",
              nrow(x$nodes), nrow(x$edges), nrow(x$pipe_support)))
  invisible(x)
}

#' @title Run one atomic reservoir step
#' @description Routes, jointly allocates, extracts, records position
#'   topology, and atomically commits one residual update. All pipes read
#'   the same input supply snapshot. The returned conservation record is
#'   in supply units; signal values are observations, not conserved water.
#' @param reservoir a \code{visualr_reservoir}.
#' @param pipes one pipe or list of pipes.
#' @param preferences optional preference matrix; default uses
#'   \code{route_pipes}.
#' @param k optional nearest-node support used only for automatic routing.
#' @param tolerance allocation and conservation tolerance.
#' @param max_iter maximum simultaneous allocation rounds.
#' @return object of class \code{visualr_reservoir_step}.
#' @examples
#' field <- new_reservoir(1:6, cbind(x = seq(0, 1, length.out = 6)),
#'                        supply = rep(1, 6), capacity = rep(0.5, 6))
#' pipes <- list(
#'   new_reservoir_pipe("a", 0.8, phase = 0),
#'   new_reservoir_pipe("b", 0.8, phase = 0.5)
#' )
#' reservoir_step(field, pipes, k = 3)
reservoir_step <- function(reservoir, pipes, preferences = NULL, k = NULL,
                           tolerance = 1e-10, max_iter = 1000L) {
  if (!inherits(reservoir, "visualr_reservoir")) {
    stop("`reservoir` must be a visualr_reservoir.", call. = FALSE)
  }
  pipes <- validate_pipes(pipes)
  if (is.null(preferences)) preferences <- route_pipes(reservoir, pipes, k)
  allocation <- allocate_pipes(reservoir, pipes, preferences,
                               tolerance, max_iter)
  topology <- reservoir_topology(reservoir, allocation,
                                 threshold = max(tolerance, .Machine$double.eps))
  outputs <- allocation_outputs(reservoir, allocation)

  reservoir_out <- reservoir
  extracted_by_node <- colSums(allocation$matrix)
  reservoir_out$supply <- pmax(0, reservoir$supply - extracted_by_node)
  reservoir_out$tick <- reservoir$tick + 1L

  input_supply <- sum(reservoir$supply)
  extracted <- sum(extracted_by_node)
  remaining <- sum(reservoir_out$supply)
  error <- input_supply - extracted - remaining
  conservation <- list(input = input_supply, extracted = extracted,
                       remaining = remaining, error = error,
                       ok = abs(error) <= max(tolerance, 1e-12))
  if (!conservation$ok) {
    stop("reservoir supply conservation failed (commit aborted).",
         call. = FALSE)
  }

  event <- list(tick = reservoir_out$tick,
                pipe_id = vapply(pipes, `[[`, character(1), "id"),
                node_draw = stats::setNames(extracted_by_node,
                                            reservoir$node_id),
                conservation_error = error)
  reservoir_out$trace <- c(reservoir$trace, list(event))

  structure(
    list(reservoir_in = reservoir, pipes_in = pipes,
         preferences = preferences, allocation = allocation,
         outputs = outputs, topology = topology,
         reservoir_out = reservoir_out,
         pipes_out = advance_pipes(pipes),
         conservation = conservation),
    class = "visualr_reservoir_step"
  )
}

#' @export
print.visualr_reservoir_step <- function(x, ...) {
  cat(sprintf("<visualr_reservoir_step> tick=%d pipes=%d extracted=%.6g\n",
              x$reservoir_out$tick, nrow(x$outputs),
              x$conservation$extracted))
  cat(sprintf("  conservation=%s | topology=%d nodes/%d edges\n",
              x$conservation$ok, nrow(x$topology$nodes),
              nrow(x$topology$edges)))
  invisible(x)
}
