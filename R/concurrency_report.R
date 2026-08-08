# == concurrency_report: v0.4.x concurrent-throughput harness ==========
# Reproducible measurement of the batch_compute concurrency speedup
# across task sizes and core counts. This is the v0.4.x Efficiency-gate
# "concurrent throughput" measurement (DEVELOPMENT_PLAN_v0.5.0.md §10).
#
# Design (align with plan §6 concurrency contract):
#   - determinism is assumed (verified); this measures SPEEDUP, not correctness
#   - speedup is bounded (fork overhead limits linear scaling) -- reported honestly
#   - each cell: t_serial / t_parallel, recomputed fresh (no cached results)
#
# Returns a data.frame with one row per (size, ncores) combination:
#   size       -- number of pal states
#   ncores     -- cores requested
#   serial_s   -- elapsed seconds at ncores=1
#   parallel_s -- elapsed seconds at requested ncores
#   speedup    -- serial_s / parallel_s
#   fallback   -- whether requested cores actually ran (FALSE = real multicore)

#' @title Benchmark batch_compute concurrency speedup
#' @description Reproducible measurement of concurrent-to-serial speedup
#'   for \code{batch_compute} across task sizes and core counts. Output is
#'   a data.frame, one row per (size, ncores) pair.
#' @param sizes integer vector of task sizes (number of pal states).
#' @param ncores_vec integer vector of cores to test (at least 1).
#' @param op single character, operator applied (default "orbit_rotate").
#' @param trials integer, number of timing trials per cell (default 3).
#' @return data.frame with columns: size, ncores, serial_s, parallel_s,
#'   speedup, fallback.
#' @examples
#' concurrency_report(sizes = c(200, 1000), ncores_vec = c(1, 2, 4), trials = 1)
concurrency_report <- function(sizes = c(200L, 1000L, 5000L),
                               ncores_vec = c(1L, 2L, 4L),
                               op = "orbit_rotate",
                               trials = 3L) {
  if (!is.numeric(sizes) || any(sizes < 1L)) {
    stop("`sizes` must be positive integers.", call. = FALSE)
  }
  if (!is.numeric(ncores_vec) || any(ncores_vec < 1L)) {
    stop("`ncores_vec` must be positive integers.", call. = FALSE)
  }
  if (!is.numeric(trials) || trials < 1L) {
    stop("`trials` must be >= 1.", call. = FALSE)
  }
  sizes <- as.integer(sizes)
  ncores_vec <- as.integer(ncores_vec)
  trials <- as.integer(trials)

  p4 <- new_pal_state(c("A", "B", "C", "D"), "e")

  rows <- list()
  for (n in sizes) {
    pals <- rep(list(p4), n)
    # pre-materialize once (warmup + shared grid setup)
    invisible(batch_compute(pals, op, ncores = 1L))

    # serial baseline
    t_ser <- min(replicate(trials,
      system.time(batch_compute(pals, op, ncores = 1L))[["elapsed"]]))

    for (nc in ncores_vec) {
      if (nc == 1L) {
        rows[[length(rows) + 1L]] <- data.frame(
          size = n, ncores = nc,
          serial_s = t_ser, parallel_s = t_ser,
          speedup = 1.0, fallback = FALSE, stringsAsFactors = FALSE)
        next
      }
      t_par <- min(replicate(trials,
        system.time(batch_compute(pals, op, ncores = nc))[["elapsed"]]))
      r <- batch_compute(pals, op, ncores = nc)
      rows[[length(rows) + 1L]] <- data.frame(
        size = n, ncores = nc,
        serial_s = t_ser, parallel_s = t_par,
        speedup = t_ser / t_par,
        fallback = isTRUE(r$fallback), stringsAsFactors = FALSE)
    }
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' @title Concurrency health check (fork availability)
#' @description Reports whether the current platform supports true
#'   multi-core execution via fork (mclapply), or must fall back to
#'   serial. This is the v0.4.x "explicit worker/fallback reporting"
#'   companion to \code{batch_compute} (plan §6).
#' @return list with fields: platform (OS type), fork_supported
#'   (logical), detect_cores (total cores), recommended_cores (cores
#'   batch_compute should use), effective_mode ("multicore" | "psock"
#'   | "serial"). v0.4.x: Windows now uses PSOCK for true parallelism,
#'   so effective_mode is "psock" on multi-core Windows.
#' @examples
#' concurrency_health()
concurrency_health <- function() {
  platform <- .Platform$OS.type
  # Fork (mclapply) is unavailable on Windows; Unix/macOS use it.
  fork_supported <- (platform != "windows")
  total <- parallel::detectCores()
  if (is.na(total) || total < 1L) total <- 1L
  # batch_compute default: detectCores() - 1, min 1
  recommended <- max(1L, total - 1L)
  # v0.4.x engine resolution (mirrors batch_compute auto):
  #   Unix+multi-core -> multicore (fork)
  #   Windows+multi-core -> psock (true parallelism, was serial pre-PSOCK)
  #   single core -> serial
  effective <- if (recommended > 1L) {
    if (fork_supported) "multicore" else "psock"
  } else {
    "serial"
  }
  list(
    platform = platform,
    fork_supported = fork_supported,
    detect_cores = as.integer(total),
    recommended_cores = as.integer(recommended),
    effective_mode = effective
  )
}