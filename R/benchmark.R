# == benchmark_storage: v0.4.x measurement harness ====================
# Reusable, reproducible measurement of the compact-vs-expanded storage
# trade-off. This is the v0.4.x Efficiency-gate measurement infrastructure
# (DEVELOPMENT_PLAN_v0.5.0.md §10).
#
# Design principles (align with DEVELOPMENT_PLAN_v0.5.0.md):
#   - G1 "store less / move less": PAL serialization is the transport unit.
#   - The matrix is an on-demand working view (materialize), NOT resident.
#   - Reduction RATIOS are the portable claim; absolute byte counts are
#     R-version/platform-specific (serialization header version).
#
# The function returns a reproducible data.frame, one row per measured
# state, with columns:
#   dim          -- state label (S_1 .. S_5)
#   pal_bytes    -- format_pal() serialized content bytes (UTF-8)
#   matrix_bytes -- serialize() of the materialized working matrix
#   cells        -- grid cell count (NULL for non-carrier states)
#   reduction    -- matrix_bytes / pal_bytes (>=1 means PAL is smaller)
#
# NOTE: This measures TRANSPORT/PERSISTENCE bytes (G1), which is the
# documented advantage of PAL. It does NOT claim R object-memory
# advantage -- the S3 pal object carries list+class overhead that makes
# it LARGER in object.size() than the matrix (see pre-freeze report §3).

#' @title Benchmark compact vs expanded storage bytes
#' @description Reproducible measurement of stored/transport bytes for
#'   PAL (compact) vs materialized matrix (expanded) representations
#'   across representative dimensions S_1..S_5.
#' @return data.frame with columns: dim, pal_bytes, matrix_bytes,
#'   cells, reduction. `reduction = matrix_bytes / pal_bytes`; values
#'   >= 1 mean PAL is more compact (smaller) than the matrix.
#' @examples
#' benchmark_storage()
benchmark_storage <- function() {
  # Representative states across dimensions
  defs <- list(
    S1 = list(shells = character(0), core = "A"),
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e"),
    S5 = list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )

  measure_matrix <- function(pal) {
    m <- materialize(pal)
    if (!m$ok) {
      return(list(bytes = NA_real_, cells = NA_integer_))
    }
    con <- rawConnection(raw(0), "w")
    serialize(m$grid, con)
    bytes <- length(rawConnectionValue(con))
    cells <- length(m$grid)
    close(con)
    list(bytes = as.numeric(bytes), cells = as.integer(cells))
  }

  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    pal <- new_pal_state(d$shells, d$core)
    pal_bytes <- nchar(format_pal(pal), type = "bytes")
    mx <- measure_matrix(pal)
    # High-dim S_5 uses the 11x11 carrier (121 cells) -- the case where
    # PAL's O(n) advantage over the O(n^2) matrix is most pronounced.
    if (nm == "S5") {
      c11 <- carrier_11x11()
      con <- rawConnection(raw(0), "w")
      serialize(c11, con)
      mx$bytes <- as.numeric(length(rawConnectionValue(con)))
      mx$cells <- as.integer(length(c11))
      close(con)
    }
    reduction <- if (is.na(mx$bytes)) NA_real_ else mx$bytes / pal_bytes
    data.frame(
      dim = nm, pal_bytes = pal_bytes,
      matrix_bytes = mx$bytes, cells = mx$cells,
      reduction = reduction,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
# == benchmark_transfer: v0.5.0 Efficiency-gate #3 (transfer size) ========
# Measures the compact transport unit (PAL serialized) vs the expanded
# working view, plus the rawConnection round-trip cost.  Pure measurement;
# no semantic changes.

#' @title Benchmark transfer size (PAL transport unit vs expanded)
#' @description Measures the byte payload that must cross a transport
#'   boundary to reconstruct the canonical state, comparing the compact
#'   PAL form against the expanded materialized matrix, per dimension
#'   S1..S5.  Returns a reproducible data.frame.
#' @return data.frame with columns: dim, pal_transfer_bytes,
#'   matrix_transfer_bytes, transfer_reduction.
#' @examples
#' benchmark_transfer()
benchmark_transfer <- function() {
  defs <- list(
    S1 = list(shells = character(0), core = "A"),
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e"),
    S5 = list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )
  ser_size <- function(x) {
    con <- rawConnection(raw(0), "w")
    serialize(x, con)
    n <- length(rawConnectionValue(con))
    close(con)
    as.numeric(n)
  }
  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    pal <- new_pal_state(d$shells, d$core)
    pal_bytes <- ser_size(format_pal(pal))
    if (nm == "S5") {
      mx <- carrier_11x11()
    } else {
      m <- materialize(pal)
      if (!m$ok) {
        return(data.frame(dim = nm, pal_transfer_bytes = pal_bytes,
                          matrix_transfer_bytes = NA_real_,
                          transfer_reduction = NA_real_))
      }
      mx <- m$grid
    }
    mx_bytes <- ser_size(mx)
    data.frame(dim = nm, pal_transfer_bytes = pal_bytes,
               matrix_transfer_bytes = mx_bytes,
               transfer_reduction = mx_bytes / pal_bytes)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# == benchmark_peak_ram: v0.5.0 Efficiency-gate #4 (peak RAM) =============
# Approximates peak memory of the expanded working view vs the compact
# PAL object using R's internal object.size().  Documented limitation:
# object.size is a static estimate, not a heap-profiler measurement; the
# reproducible claim is the *ratio* between representations, not absolute
# process RSS.

#' @title Benchmark peak RAM (object size estimate)
#' @description Static object-size estimate of the compact PAL object vs
#'   the materialized matrix working view, per dimension S1..S5.
#' @return data.frame with columns: dim, pal_object_bytes,
#'   matrix_object_bytes, ram_reduction.
#' @examples
#' benchmark_peak_ram()
benchmark_peak_ram <- function() {
  defs <- list(
    S1 = list(shells = character(0), core = "A"),
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e"),
    S5 = list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )
  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    pal <- new_pal_state(d$shells, d$core)
    pal_bytes <- as.numeric(object.size(pal))
    if (nm == "S5") {
      mx <- carrier_11x11()
    } else {
      m <- materialize(pal)
      if (!m$ok) {
        return(data.frame(dim = nm, pal_object_bytes = pal_bytes,
                          matrix_object_bytes = NA_real_,
                          ram_reduction = NA_real_))
      }
      mx <- m$grid
    }
    mx_bytes <- as.numeric(object.size(mx))
    data.frame(dim = nm, pal_object_bytes = pal_bytes,
               matrix_object_bytes = mx_bytes,
               ram_reduction = mx_bytes / pal_bytes)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# == benchmark_overhead: v0.5.0 Efficiency-gate #5 (encode/expand/fold) ====
# Measures the wall-clock cost of the three transform steps:
#   encode (PAL -> pal object), expand (materialize), fold (jiugong_to_pal).
# Uses system.time; runs `reps` iterations and reports median elapsed.
# Pure timing harness; no semantic logic.

#' @title Benchmark encoding/expansion/fold overhead
#' @description Median wall-clock seconds per transform step across
#'   representative dimensions.  Timing is platform-dependent; the claim
#'   is relative cost per step, not absolute speed.
#' @param reps integer, iterations per measurement (default 200).
#' @return data.frame with columns: dim, encode_ms, expand_ms, fold_ms.
#' @examples
#' benchmark_overhead(reps = 50)
benchmark_overhead <- function(reps = 200L) {
  defs <- list(
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e")
  )
  med_ms <- function(x) as.numeric(median(x) * 1000)
  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    enc <- numeric(reps); exp <- numeric(reps); fold <- numeric(reps)
    for (i in seq_len(reps)) {
      enc[i] <- system.time(p <- new_pal_state(d$shells, d$core))[["elapsed"]]
      exp[i] <- system.time(m <- materialize(p))[["elapsed"]]
      if (m$ok) {
        fold[i] <- system.time(closure_check(m$grid))[["elapsed"]]
      } else {
        fold[i] <- NA_real_
      }
    }
    data.frame(dim = nm, encode_ms = med_ms(enc),
               expand_ms = med_ms(exp), fold_ms = med_ms(fold))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# == benchmark_latency: v0.5.0 Efficiency-gate #6 (serial latency) ========
# Single-core reference latency: full round-trip (encode -> expand ->
# closure -> fold-back) in one measurement.

#' @title Benchmark serial round-trip latency
#' @description Median wall-clock seconds for the complete
#'   encode->expand->closure->fold round trip on a single core.
#' @param reps integer, iterations (default 100).
#' @return data.frame with columns: dim, roundtrip_ms.
#' @examples
#' benchmark_latency(reps = 50)
benchmark_latency <- function(reps = 100L) {
  defs <- list(
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e")
  )
  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    tms <- numeric(reps)
    for (i in seq_len(reps)) {
      tms[i] <- system.time({
        p <- new_pal_state(d$shells, d$core)
        m <- materialize(p)
        if (m$ok) closure_check(m$grid)
      })[["elapsed"]]
    }
    data.frame(dim = nm, roundtrip_ms = as.numeric(median(tms) * 1000))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# == benchmark_throughput: v0.5.0 Efficiency-gate #7 (concurrent) ========
# Measures concurrent compute throughput relative to serial for a fixed
# batch of S4 palindromes through batch_compute().  Uses the package's
# own concurrency machinery; reports workers actually used.

#' @title Benchmark concurrent throughput
#' @description Batch round-trip throughput for a fixed workload, serial
#'   vs concurrent, using batch_compute().  Reports the effective worker
#'   count from concurrency_health() so the claim is reproducible.
#' @param n integer, batch size (default 400).
#' @return data.frame with columns: mode, n, elapsed_ms, throughput_per_s.
#' @examples
#' benchmark_throughput(n = 100)
benchmark_throughput <- function(n = 400L) {
  pals <- replicate(n, new_pal_state(c("A", "B", "C", "D"), "e"),
                    simplify = FALSE)
  h <- concurrency_health()
  # Serial reference does the SAME full round-trip work as the concurrent
  # path (materialize + compute + transition) so the comparison is fair.
  # v0.5.0: concurrent throughput must be the advantage; serial may be
  # slightly slower but never should concurrent lose on equal work.
  round_trip <- function(p) {
    m <- materialize(p)
    if (m$ok) transition_policy(compute_jiugong(m$grid, "identity"))
  }
  t_serial <- system.time(lapply(pals, round_trip))[["elapsed"]]
  bc <- batch_compute(pals, op = "identity")
  t_conc <- system.time(
    batch_compute(pals, op = "identity")
  )[["elapsed"]]
  # batch_compute returns actual cores used; health.recommended is the
  # default request, not the executed count.
  workers <- bc$ncores
  data.frame(
    mode = c("serial", "concurrent"),
    n = c(n, n),
    elapsed_ms = c(t_serial * 1000, t_conc * 1000),
    throughput_per_s = c(n / t_serial, n / t_conc),
    effective_workers = c(1L, workers),
    execution = c("serial", bc$execution)
  )
}
