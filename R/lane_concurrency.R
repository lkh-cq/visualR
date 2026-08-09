# == Concurrent lane fabric: parallel execution of orbit lanes =======
# Topology Operator ABI v0.1 — execution fabric layer.
# R = operator language (defines the lanes); CPU backend = execution
# fabric. This file gives the concurrent execution of the five orbit
# lanes (A/B/C/D/e) over one snapshot, with the SAME engine abstraction
# as batch_compute: sequential / PSOCK / fork(multicore).
#
# Contract (user 2026-08-08): result_serial == result_PSOCK ==
# result_fork — differences are PERFORMANCE only, never semantics.

# =====================================================================
# Engine resolution (shared with batch_compute semantics)
# =====================================================================

# Internal: resolve the effective lane engine (never silent).
resolve_lane_engine <- function(engine) {
  engine <- match.arg(engine, c("auto", "multicore", "psock", "serial"))
  is_win <- .Platform$OS.type == "windows"
  switch(engine,
    serial = "serial",
    multicore = if (is_win) "serial-fallback" else "multicore",
    psock = "psock",
    auto = if (is_win) "psock" else "multicore"
  )
}

# Internal: one lane job (pure function over the snapshot).
lane_job <- function(nm, snap, kernels, pack) {
  cell <- snap$cell
  if (nm == "e") {
    kernels$e(cell$singularity, cell$phase, pack)
  } else {
    kernels[[nm]](cell$orbits[[nm]], cell$phase, pack)
  }
}

# =====================================================================
# Concurrent lane execution
# =====================================================================

#' @title Execute lanes in parallel over one snapshot
#' @description Concurrent execution of the five orbit lanes
#'   (A/B/C/D/e) over ONE frozen snapshot. Engine semantics match
#'   batch_compute: serial / psock / multicore(fork) with explicit
#'   fallback reporting. Result is semantically identical across
#'   engines — only performance differs (frozen contract).
#' @param snap a \code{visualr_snapshot}.
#' @param kernels named list of kernel functions (default: all
#'   identity).
#' @param engine character: "auto" (default: multicore on Unix, psock on
#'   Windows), "multicore", "psock", "serial".
#' @param ncores integer; number of workers (default: detectCores()-1).
#' @return list with fields: deltas (named list A/B/C/D/e), engine
#'   (requested), effective (actual), ncores (used), fallback (logical).
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' snap <- snapshot(new_topology_carrier(p))
#' res <- execute_lanes_parallel(snap, lane_kernels("rotate"))
#' res$deltas$A$result  # c("B","B")
execute_lanes_parallel <- function(snap, kernels = NULL,
                                   engine = c("auto", "multicore", "psock",
                                              "serial"),
                                   ncores = NULL) {
  if (!inherits(snap, "visualr_snapshot")) {
    stop("`snap` must be a visualr_snapshot.", call. = FALSE)
  }
  engine <- match.arg(engine)
  if (is.null(kernels)) kernels <- lane_kernels("identity")
  # validate kernels list has the required lanes (orbit labels + e)
  cell <- snap$cell
  lane_names <- names(cell$orbits)
  if (is.null(lane_names) || any(lane_names == "")) {
    lane_names <- LETTERS[seq_along(cell$orbits)]
  }
  need <- c(lane_names, "e")
  if (!all(need %in% names(kernels))) {
    stop(sprintf("`kernels` must have names: %s",
                 paste(need, collapse = "/")), call. = FALSE)
  }

  if (is.null(ncores)) {
    ncores <- parallel::detectCores()
    if (is.na(ncores) || ncores < 1L) ncores <- 1L
    ncores <- ncores - 1L
    if (ncores < 1L) ncores <- 1L
  }
  ncores <- as.integer(ncores)
  if (ncores < 1L) stop("`ncores` must be >= 1.", call. = FALSE)

  # pack resolution for kernels that need rules (P0-1: pack authority)
  pack <- NULL
  cell <- snap$cell
  if (!is.null(cell$origin) && is.list(cell$origin) &&
      !is.null(cell$origin$pal)) {
    pack <- tryCatch(pal_resolve_pack(cell$origin$pal), error = function(e) NULL)
  }
  if (is.null(pack)) {
    pack <- tryCatch(pal_resolve_pack(DEFAULT_MAPPING_PACK_ID),
                     error = function(e) NULL)
  }

  requested <- engine
  effective <- resolve_lane_engine(engine)
  # lane_names already computed above (orbit labels); singularity last.
  lanes <- c(lane_names, "e")

  if (ncores == 1L || effective %in% c("serial", "serial-fallback")) {
    res <- lapply(lanes, lane_job, snap = snap, kernels = kernels, pack = pack)
    used <- 1L
  } else if (effective == "psock") {
    cl <- parallel::makePSOCKcluster(ncores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Worker needs the lane_job function and the kernel functions. In a
    # dev (load_all) session the package is not installed in the
    # worker's library, so export the function BODIES explicitly rather
    # than library(visualR) — the kernels are pure closures already in
    # the calling environment.
    parallel::clusterExport(cl, c("lane_job", "snap", "kernels", "pack"),
                            envir = environment())
    res <- parallel::parLapply(cl, lanes, function(nm) {
      lane_job(nm, snap, kernels, pack)
    })
    used <- ncores
  } else { # multicore (fork)
    res <- parallel::mclapply(lanes, lane_job, snap = snap,
                              kernels = kernels, pack = pack,
                              mc.cores = ncores)
    used <- ncores
  }

  names(res) <- lanes
  requested_cores <- ncores
  fallback <- (requested_cores > 1L) && (used < requested_cores)
  actual_execution <- if (effective == "serial-fallback") "serial-fallback"
                      else if (used == 1L) "serial" else effective

  list(deltas = res, engine = requested, effective = effective,
       ncores = used, fallback = fallback,
       execution = actual_execution)
}

# =====================================================================
# Integrated: run_topology_pipeline_parallel
# =====================================================================

#' @title Full ABI pipeline with concurrent lanes
#' @description run_topology_pipeline with the lanes executed in
#'   parallel over the snapshot. Everything else identical (barrier,
#'   reconcile, commit, PAL re-encode). Result is semantically equal to
#'   the serial pipeline.
#' @param pal a \code{visualr_pal} object.
#' @param kernels kernel-name spec or named list of lane kernels.
#' @param engine character: concurrency engine for the lanes.
#' @param ncores integer; worker count.
#' @return list with fields of run_topology_pipeline plus engine info.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' run_topology_pipeline_parallel(p, "rotate")
run_topology_pipeline_parallel <- function(pal, kernels = NULL,
                                           engine = c("auto", "multicore",
                                                      "psock", "serial"),
                                           ncores = NULL) {
  validate_pal(pal)
  engine <- match.arg(engine)
  carrier_in <- new_topology_carrier(pal)
  snap <- snapshot(carrier_in)
  if (is.character(kernels) || is.list(kernels)) {
    kernels <- lane_kernels(kernels)
  }
  lr <- execute_lanes_parallel(snap, kernels, engine, ncores)
  deltas <- lr$deltas
  barrier(deltas)
  rec <- reconcile(deltas, carrier_in$cell)
  carrier_out <- commit(rec, carrier_in)
  pal_out <- cell_to_pal(carrier_out$cell, pal)
  list(carrier_in = carrier_in, snapshot = snap, deltas = deltas,
       barrier = TRUE, reconciled = rec, carrier_out = carrier_out,
       pal_out = pal_out, lanes = lr)
}
