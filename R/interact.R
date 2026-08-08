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
#'   (or grammar text), materializes it via the UNIFIED dispatch
#'   (\code{materialize}), applies an emergence operator, checks the
#'   closure FACT (\code{closure_check}) and derives the scheduling
#'   ACTION (\code{transition_policy}). Designed for REPL
#'   experimentation: every step is visible.
#' @param x a visualr_pal object OR a palindrome grammar string
#' @param op single character, operator name (see \code{compute_jiugong})
#' @param carrier single character, carrier for materialize:
#'   "auto" (default) | "canonical_jiugong" | "gamma_local" |
#'   "carrier_11x11"
#' @param verbose logical, print the pipeline trace. Default TRUE.
#' @return list with fields: input, carrier (resolved), expanded
#'   (working matrix), computed (operator output), closed (logical
#'   FACT), action (promote/transient/recurse/reject), fold_back
#'   (pal if promoted, else NULL), trace
#' @examples
#' pal_pipe("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
pal_pipe <- function(x, op = "identity", carrier = "auto", verbose = TRUE) {
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

  # 2) materialize via UNIFIED dispatch (P0-2: no semantic fork)
  m <- materialize(pal, carrier)
  if (!m$ok) {
    stop(sprintf("Materialization failed for carrier '%s'.", m$carrier),
         call. = FALSE)
  }
  expanded <- m$grid

  # 3) compute — typed dispatch (P0-3, v0.2.2): operators are defined
  #    per carrier SHAPE. carrier_11x11 is currently a materializable
  #    view only (no 11x11 operator ABI exists yet); compute entry
  #    points require a 3x3 carrier. Fail with a clear typed error
  #    instead of a confusing "grid must be 3x3" downstream.
  if (!identical(dim(expanded), c(3L, 3L))) {
    stop(sprintf(
      "Carrier '%s' materialized to %dx%d, but operators are defined for 3x3 carriers only (typed dispatch, P0-3). Use carrier=\"auto\" or a 3x3 carrier.",
      m$carrier, nrow(expanded), ncol(expanded)), call. = FALSE)
  }
  computed <- compute_jiugong(expanded, op, mapping_pack_id = pal$mapping_pack_id)

  # 4) closure FACT + scheduling ACTION (P0-5: separated)
  closed <- closure_check(computed, mapping_pack_id = pal$mapping_pack_id)
  action <- transition_policy(computed, mapping_pack_id = pal$mapping_pack_id)

  # 5) fold back if promoted (interaction state -> storage-ready)
  fold_back <- NULL
  if (action == "promote" && closed) {
    jg <- structure(list(grid = computed,
                         mapping_pack_id = pal$mapping_pack_id),
                    class = "visualr_jiugong")
    fold_back <- tryCatch(jiugong_to_pal(jg), error = function(e) NULL)
  }

  trace <- list(
    input = pal_encode(pal),
    carrier = m$carrier,
    operator = op,
    closed = closed,
    action = action
  )

  if (verbose) {
    cat("== pal_pipe ======================================\n")
    cat("input:  ", pal_encode(pal), "\n", sep = "")
    cat(sprintf("carrier: %s\n", m$carrier))
    cat("expanded:\n")
    print(expanded, quote = FALSE)
    cat(sprintf("operator: %s\n", op))
    cat("computed:\n")
    print(computed, quote = FALSE)
    cat(sprintf("closure FACT: %s\n", closed))
    cat(sprintf("action: %s\n", action))
    if (!is.null(fold_back)) {
      cat("fold_back:", pal_encode(fold_back), "\n")
    } else {
      cat("fold_back: (none -- state remains in working memory)\n")
    }
    cat("================================================-\n")
  }

  list(input = pal, carrier = m$carrier, expanded = expanded,
       computed = computed, closed = closed, action = action,
       fold_back = fold_back, trace = trace)
}

#' @title Parallel bulk computation across many pal states
#' @description Apply an emergence operator to N pal states in parallel
#'   (mclapply across available cores) through the UNIFIED materialize
#'   dispatch. Returns per-state closure verdicts plus a consistency
#'   summary. R parallel is the benchmark engine.
#' @param pals list of visualr_pal objects
#' @param op single character, operator name
#' @param carrier single character, carrier for materialize
#'   (default "auto": S_4 -> canonical_jiugong, else gamma_local)
#' @param ncores integer, number of cores (default: detectCores()-1)
#' @param engine character, concurrency engine: "auto" (default:
#'   multicore on Unix, psock on Windows), "multicore" (mclapply,
#'   Unix only -- falls back to serial on Windows), "psock" (PSOCK
#'   cluster, works everywhere), or "serial". Never silently degrades:
#'   the effective engine is always reported in the return value.
#' @return list with fields: n, ncores (effective cores used),
#'   requested_cores (as requested), fallback (logical: TRUE when
#'   requested >1 core but execution fell back to serial), execution
#'   ("serial" | "serial-fallback" | "multicore" | "psock"), engine
#'   (requested engine), carrier, results (per-state action),
#'   n_promote, n_transient, n_recurse, n_reject, consistent (logical)
#' @examples
#' batch_compute(list(new_pal_state(c("A","B","C","D"), "e"),
#'                    new_pal_state(c("A","B","C"), "D")), "identity", ncores = 1)
batch_compute <- function(pals, op = "identity", carrier = "auto",
                          ncores = NULL, engine = c("auto", "multicore",
                                                    "psock", "serial")) {
  engine <- match.arg(engine)
  if (!is.list(pals) || length(pals) == 0L) {
    stop("`pals` must be a non-empty list of visualr_pal objects.", call. = FALSE)
  }
  for (p in pals) validate_pal(p)

  if (is.null(ncores)) {
    ncores <- parallel::detectCores()
    if (is.na(ncores) || ncores < 1L) ncores <- 1L
    ncores <- ncores - 1L
    if (ncores < 1L) ncores <- 1L
  }
  ncores <- as.integer(ncores)
  if (ncores < 1L) stop("`ncores` must be >= 1.", call. = FALSE)

  # Materialize all states via UNIFIED dispatch (P0-2: no semantic fork)
  mats <- lapply(pals, function(p) materialize(p, carrier))
  if (any(!vapply(mats, function(m) m$ok, logical(1)))) {
    stop("Materialization failed for at least one pal state.", call. = FALSE)
  }
  grids <- lapply(mats, function(m) m$grid)
  resolved_carrier <- mats[[1]]$carrier
  ids <- vapply(pals, function(p) p$mapping_pack_id, character(1))

  work <- function(i) {
    out <- compute_jiugong(grids[[i]], op, mapping_pack_id = ids[i])
    transition_policy(out, mapping_pack_id = ids[i])
  }

  # Resolve the effective engine (never silent):
  #   user "serial"              -> serial
  #   user "multicore" on Unix   -> mclapply
  #   user "multicore" on Win    -> serial fallback (reported)
  #   user "psock"               -> PSOCK cluster
  #   user "auto": Unix -> multicore, Windows -> psock
  is_win <- .Platform$OS.type == "windows"
  requested_engine <- engine
  effective <- switch(engine,
    serial = "serial",
    multicore = if (is_win) "serial-fallback" else "multicore",
    psock = "psock",
    auto = if (is_win) "psock" else "multicore"
  )

  if (ncores == 1L || effective == "serial" || effective == "serial-fallback") {
    verdicts <- vapply(seq_along(grids), work, character(1L))
    used <- 1L
  } else if (effective == "psock") {
    cl <- parallel::makePSOCKcluster(ncores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterEvalQ(cl, library(visualR))
    parallel::clusterExport(cl, c("grids", "ids", "op"), envir = environment())
    verdicts <- unlist(parallel::parLapply(cl, seq_along(grids), function(i) {
      out <- compute_jiugong(grids[[i]], op, mapping_pack_id = ids[i])
      transition_policy(out, mapping_pack_id = ids[i])
    }))
    used <- ncores
  } else { # multicore
    verdicts <- unlist(parallel::mclapply(seq_along(grids), work,
                                          mc.cores = ncores))
    used <- ncores
  }

  # v0.4.x: report silent degradation explicitly (plan §6).
  # A platform-specific serial fallback must be reported as a fallback,
  # NOT as proof that a true multi-core path was exercised.
  # fallback = requested >1 core but effective execution was serial.
  requested_cores <- ncores
  fallback <- (requested_cores > 1L) && (used < requested_cores)

  # execution reports the ACTUAL execution path. When the platform
  # engine resolved to a serial fallback (engine="multicore" on
  # Windows), report "serial-fallback" so the caller knows the request
  # was degraded. Only a plain ncores==1 serial run reports "serial".
  actual_execution <- if (effective == "serial-fallback") "serial-fallback"
                      else if (used == 1L) "serial" else effective

  n_promote <- sum(verdicts == "promote")
  n_transient <- sum(verdicts == "transient")
  n_recurse <- sum(verdicts == "recurse")
  n_reject <- sum(verdicts == "reject")

  list(n = length(pals), ncores = used, requested_cores = requested_cores,
       fallback = fallback, engine = requested_engine, carrier = resolved_carrier,
       execution = actual_execution,
       results = verdicts,
       n_promote = n_promote, n_transient = n_transient,
       n_recurse = n_recurse, n_reject = n_reject,
       consistent = (n_promote + n_transient + n_recurse + n_reject) == length(pals))
}

#' @title Full interaction loop: new state -> jiugong -> meta-operator
#' @description The complete fold-back closure: compute a new interaction
#'   state from a pal, render it as jiugong, and fold it back to a
#'   storage-ready meta-operator state. Demonstrates the whole
#'   "storage -> compute -> fold-back" loop in one command.
#'
#'   v0.2.1 (P0-6): NEVER silently discards computation. "Not closed"
#'   does NOT mean "nothing happened". Returns a
#'   \code{visualr_compute_result} carrying input, carrier, computed,
#'   closure fact, next action and trace.
#' @param x a visualr_pal or grammar string
#' @param op single character, operator name
#' @return \code{visualr_compute_result} with fields: input, carrier,
#'   computed, closed (logical fact), action (promote/transient/recurse/
#'   reject), fold_back (pal if promoted, else NULL), trace
#' @examples
#' interact("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")
interact <- function(x, op = "identity") {
  res <- pal_pipe(x, op, verbose = FALSE)

  action <- res$action
  fold_back <- if (action == "promote") res$fold_back else NULL

  structure(
    list(
      input = res$input,
      carrier = res$carrier,
      computed = res$computed,
      closed = res$closed,
      action = action,
      fold_back = fold_back,
      trace = res$trace
    ),
    class = "visualr_compute_result"
  )
}

#' @export
print.visualr_compute_result <- function(x, ...) {
  cat("<visualr_compute_result> action=", x$action,
      " closed=", x$closed, " carrier=", x$carrier, "\n", sep = "")
  cat("  input: ", pal_encode(x$input), "\n", sep = "")
  if (!is.null(x$fold_back)) {
    cat("  fold_back: ", pal_encode(x$fold_back), "\n", sep = "")
  } else {
    cat("  fold_back: (none -- state remains in working memory)\n")
  }
  invisible(x)
}
