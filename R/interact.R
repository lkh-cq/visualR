# == Interactive + concurrent layer (R is the BENCHMARK) ============-
# Frozen positioning 2026-08-07: R interactive REPL + parallel compute
# carry the "storage -> compute -> fold-back" loop. Python is glue.
#
# pal_pipe()   -- one-command interactive pipeline:
#                 pal state -> expand (jiugong/carrier) -> operator
#                 -> closure gate -> fold-back decision, human-readable
# batch_compute() -- parallel bulk computation across many pal states
#                 (mclapply; falls back to serial when fork unavailable)
# interact()   -- full loop: new interaction state -> jiugong format
#                 -> fold back to meta-operator (storage-ready)
#
# All three are R-first: interactive by default, concurrent by design.

#' @title Interactive pipeline: storage -> compute -> fold-back
#' @description One-command interactive workflow. Takes a pal state
#'   (or grammar text), expands it, applies an emergence operator,
#'   runs the closure gate, and reports the fold-back decision.
#'   Designed for REPL experimentation: every step is visible.
#' @param x a visualr_pal object OR a palindrome grammar string
#' @param op single character, operator name (see \code{compute_jiugong})
#' @param verbose logical, print the pipeline trace. Default TRUE.
#' @return list with fields: input, expanded (jiugong matrix),
#'   computed (operator output), closure, foldable (logical),
#'   fold_back (pal state if foldable, else NULL)
#' @examples
#' pal_pipe("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
pal_pipe <- function(x, op = "identity", verbose = TRUE) {
  # 1) normalize input: grammar text -> pal state
  pal <- if (inherits(x, "visualr_pal")) {
    validate_pal(x)
    x
  } else if (is.character(x) && length(x) == 1L) {
    pal_parse(x)
  } else {
    stop("`x` must be a visualr_pal or a single palindrome grammar string.",
         call. = FALSE)
  }

  # 2) expand (storage -> working matrix).
  #    S_4 (perfect-square unfolded length) -> canonical jiugong;
  #    other S_k -> gamma_field 3x3 (universal working matrix).
  expanded <- tryCatch(pal_to_jiugong(pal)$grid,
                       error = function(e) gamma_field(pal))

  # 3) compute (emergence operator, snapshot-commit)
  computed <- compute_jiugong(expanded, op)

  # 4) closure gate (fold-back decision)
  cl <- closure_jiugong(computed)
  foldable <- cl == "closed"

  # 5) fold back (interaction state -> storage-ready)
  fold_back <- NULL
  if (foldable) {
    jg <- structure(list(grid = computed,
                         mapping_pack_id = pal$mapping_pack_id),
                    class = "visualr_jiugong")
    fold_back <- tryCatch(jiugong_to_pal(jg), error = function(e) NULL)
  }

  if (verbose) {
    cat("== pal_pipe ======================================\n")
    cat("input:  ", pal_encode(pal), "\n")
    cat("expanded:\n")
    print(expanded, quote = FALSE)
    cat(sprintf("operator: %s\n", op))
    cat("computed:\n")
    print(computed, quote = FALSE)
    cat(sprintf("closure: %s\n", cl))
    cat(sprintf("foldable: %s\n", foldable))
    if (foldable && !is.null(fold_back)) {
      cat("fold_back:", pal_encode(fold_back), "\n")
    }
    cat("================================================-\n")
  }

  list(input = pal, expanded = expanded, computed = computed,
       closure = cl, foldable = foldable, fold_back = fold_back)
}

#' @title Parallel bulk computation across many pal states
#' @description Apply an emergence operator to N pal states in parallel
#'   (mclapply across available cores). Returns per-state closure
#'   verdicts plus a consistency summary. This is the concurrent
#'   computation entry point -- R parallel is the benchmark engine.
#' @param pals list of visualr_pal objects
#' @param op single character, operator name
#' @param ncores integer, number of cores (default: detectCores()-1)
#' @return list with fields: n, ncores, results (per-state closure),
#'   n_closed, n_transient, n_recurse, consistent (logical)
#' @examples
#' batch_compute(list(new_pal_state(c("A","B","C","D"), "e"),
#'                    new_pal_state(c("A","B","C"), "D")), "identity")
batch_compute <- function(pals, op = "identity", ncores = NULL) {
  if (!is.list(pals) || length(pals) == 0L) {
    stop("`pals` must be a non-empty list of visualr_pal objects.", call. = FALSE)
  }
  for (p in pals) validate_pal(p)

  if (is.null(ncores)) {
    ncores <- max(1L, parallel::detectCores() - 1L)
  }
  ncores <- as.integer(ncores)
  if (ncores < 1L) stop("`ncores` must be >= 1.", call. = FALSE)

  # Expand all states first (pure, fork-safe).
  # gamma_field gives a 3x3 working matrix for ANY S_k (S_1+);
  # pal_to_jiugong is S_4 3x3-specific (perfect-square unfolded length),
  # so it cannot serve arbitrary shell depths.
  grids <- lapply(pals, function(p) gamma_field(p))

  work <- function(i) {
    g <- grids[[i]]
    out <- compute_jiugong(g, op)
    closure_jiugong(out)
  }

  if (ncores == 1L || .Platform$OS.type == "windows") {
    verdicts <- vapply(seq_along(grids), work, character(1L))
    used <- 1L
  } else {
    verdicts <- unlist(parallel::mclapply(seq_along(grids), work,
                                          mc.cores = ncores))
    used <- ncores
  }

  n_closed <- sum(verdicts == "closed")
  n_transient <- sum(verdicts == "transient")
  n_recurse <- sum(verdicts == "recurse")

  list(n = length(pals), ncores = used,
       results = verdicts,
       n_closed = n_closed, n_transient = n_transient, n_recurse = n_recurse,
       consistent = (n_closed + n_transient + n_recurse) == length(pals))
}

#' @title Full interaction loop: new state -> jiugong -> meta-operator
#' @description The complete fold-back closure: compute a new interaction
#'   state from a pal, render it as jiugong, and fold it back to a
#'   storage-ready meta-operator state. Demonstrates the whole
#'   "storage -> compute -> fold-back" loop in one command.
#' @param x a visualr_pal or grammar string
#' @param op single character, operator name
#' @return visualr_pal: the fold-back result (storage-ready) if the
#'   computed state is closed; otherwise the original pal unchanged
#' @examples
#' interact("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
interact <- function(x, op = "identity") {
  res <- pal_pipe(x, op, verbose = FALSE)
  if (res$foldable && !is.null(res$fold_back)) {
    res$fold_back
  } else {
    res$input
  }
}
