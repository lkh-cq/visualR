# == v0.6.2 numerical/CPU evidence harness ==========================
# STATUS: reference_experimental
#
# These benchmarks make implementation cost visible without turning one
# machine's timings into a semantic or release claim. R remains the semantic
# authority. The native comparison covers only the registered integer tap
# schedule and refuses a non-identical result before reporting speed.

.benchmark_v062_integer <- function(x, name, minimum, maximum,
                                    scalar = FALSE) {
  if (!(is.integer(x) || is.numeric(x)) || length(x) < 1L || anyNA(x) ||
      any(!is.finite(x)) || any(x != trunc(x)) || any(x < minimum) ||
      any(x > maximum) || (scalar && length(x) != 1L)) {
    qualifier <- if (scalar) "one integer" else "finite integers"
    stop(sprintf("`%s` must contain %s in [%d, %d].",
                 name, qualifier, minimum, maximum), call. = FALSE)
  }
  as.integer(x)
}

.benchmark_v062_timing <- function(fn, reps, batches) {
  fn()
  samples <- numeric(batches)
  for (batch in seq_len(batches)) {
    samples[[batch]] <- system.time({
      for (iteration in seq_len(reps)) last <- fn()
      invisible(last)
    })[["elapsed"]] * 1000 / reps
  }
  as.numeric(stats::median(samples))
}

.benchmark_v062_grid <- function(side) {
  outer(
    seq_len(side), seq_len(side),
    function(row, col) {
      sin(row / side) + cos(col / side) + row * col / (side * side)
    }
  )
}

#' @title Benchmark v0.6.2 numeric observation stages
#' @description Measures deterministic, CPU-native construction, polar,
#'   spectral, gradient, bias-evidence, and signal-scheduling stages over
#'   square numeric fields. Timings are platform evidence, not frozen
#'   performance guarantees. \code{result_bytes} is a static
#'   \code{object.size} estimate, not process peak memory.
#' @param sizes positive square side lengths, limited to 257
#' @param reps positive timed repetitions per batch
#' @param batches positive number of timing batches; medians are reported
#' @return a data frame with one row per size and operation
#' @examples
#' \donttest{benchmark_numeric_observers(sizes = c(3L, 11L), reps = 5L)}
benchmark_numeric_observers <- function(sizes = c(3L, 11L, 31L),
                                        reps = 20L,
                                        batches = 3L) {
  sizes <- .benchmark_v062_integer(sizes, "sizes", 1L, 257L)
  if (anyDuplicated(sizes)) {
    stop("`sizes` must be unique.", call. = FALSE)
  }
  reps <- .benchmark_v062_integer(reps, "reps", 1L, 1000000L,
                                  scalar = TRUE)
  batches <- .benchmark_v062_integer(batches, "batches", 1L, 1000L,
                                     scalar = TRUE)

  rows <- lapply(sizes, function(side) {
    grid <- .benchmark_v062_grid(side)
    fast_signal <- new_signal_envelope(
      "benchmark_fast", "fast", "dense", 1L,
      provenance = "visualR:benchmark_v062"
    )
    slow_signal <- new_signal_envelope(
      "benchmark_slow", "slow", "sparse", 4L,
      provenance = "visualR:benchmark_v062"
    )
    make_field <- function(signal = fast_signal) {
      new_numeric_field(
        grid,
        value_semantics = "deterministic benchmark fixture",
        unit = "a.u.",
        boundary_state = "closed",
        signal = signal
      )
    }
    field <- make_field()
    slow_field <- make_field(slow_signal)
    chart <- polar_chart(field)
    plan <- compile_spectral_plan(
      field, domain = "carrier", boundary_policy = "finite_window"
    )
    spectrum <- execute_spectral_plan(field, plan)
    gradient <- field_gradient(field, chart)
    operations <- list(
      numeric_field = function() make_field(),
      polar_chart = function() polar_chart(field),
      spectral_execute = function() execute_spectral_plan(field, plan),
      spectral_inverse = function() inverse_spectral(spectrum),
      field_gradient = function() field_gradient(field, chart),
      bias_features = function() {
        bias_features(field, chart, spectrum, gradient)
      },
      signal_schedule = function() {
        compile_signal_schedule(
          list(fast = field, slow = slow_field), tick = 4L
        )
      }
    )

    do.call(rbind, lapply(names(operations), function(operation) {
      fn <- operations[[operation]]
      elapsed <- .benchmark_v062_timing(fn, reps, batches)
      sample <- fn()
      data.frame(
        operation = operation,
        side = side,
        cells = as.integer(side * side),
        reps = reps,
        batches = batches,
        median_ms = elapsed,
        result_bytes = as.numeric(utils::object.size(sample)),
        semantic_authority = "R",
        status = "reference_experimental",
        stringsAsFactors = FALSE
      )
    }))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' @title Benchmark the exact R/C99 tap schedule boundary
#' @description Times the authoritative R integer tap scheduler and, when the
#'   registered routine is loaded, its C99 accelerator. The function compares
#'   complete schedule matrices before reporting native timing. It does not
#'   benchmark graph materialization or claim that C owns runtime semantics.
#' @param widths unique positive odd PAL path widths, limited to 129
#' @param levels positive number of dilation levels
#' @param kernel_offsets ordered unique integer tap offsets
#' @param convolutions_per_level positive passes per level
#' @param reps positive timed repetitions per batch
#' @param batches positive number of timing batches
#' @return a data frame with schedule size, timing, equivalence, and speedup
#' @examples
#' \donttest{benchmark_tap_compiler(widths = c(9L, 33L), reps = 5L)}
benchmark_tap_compiler <- function(
    widths = c(9L, 33L, 65L),
    levels = 4L,
    kernel_offsets = c(-1L, 0L, 1L),
    convolutions_per_level = 2L,
    reps = 20L,
    batches = 3L) {
  widths <- .benchmark_v062_integer(widths, "widths", 1L, 129L)
  if (any(widths %% 2L != 1L)) {
    stop("`widths` must be odd for PAL paths.", call. = FALSE)
  }
  if (anyDuplicated(widths)) {
    stop("`widths` must be unique.", call. = FALSE)
  }
  reps <- .benchmark_v062_integer(reps, "reps", 1L, 1000000L,
                                  scalar = TRUE)
  batches <- .benchmark_v062_integer(batches, "batches", 1L, 1000L,
                                     scalar = TRUE)
  native_loaded <- is.loaded("C_visualr_compile_taps", PACKAGE = "visualR")

  rows <- lapply(widths, function(width) {
    args <- .normalize_compile_arguments(
      width, levels, kernel_offsets, convolutions_per_level
    )
    compile_r <- function() {
      .compile_tap_schedule_r(
        args$width, args$levels, args$kernel_offsets,
        args$convolutions_per_level, args$tap_count
      )
    }
    reference <- compile_r()
    r_ms <- .benchmark_v062_timing(compile_r, reps, batches)
    result <- data.frame(
      width = args$width,
      levels = args$levels,
      taps = args$tap_count,
      engine = "r",
      median_ms = r_ms,
      taps_per_ms = if (r_ms > 0) args$tap_count / r_ms else NA_real_,
      speedup_vs_r = 1,
      equivalent_to_r = TRUE,
      semantic_authority = "R",
      status = "reference_experimental",
      stringsAsFactors = FALSE
    )

    if (native_loaded) {
      compile_c <- function() {
        .compile_tap_schedule_c(
          args$width, args$levels, args$kernel_offsets,
          args$convolutions_per_level
        )
      }
      native <- compile_c()
      if (!identical(native, reference)) {
        stop("C99 tap benchmark differs from the R authority (fail closed).",
             call. = FALSE)
      }
      c_ms <- .benchmark_v062_timing(compile_c, reps, batches)
      result <- rbind(
        result,
        data.frame(
          width = args$width,
          levels = args$levels,
          taps = args$tap_count,
          engine = "c",
          median_ms = c_ms,
          taps_per_ms = if (c_ms > 0) args$tap_count / c_ms else NA_real_,
          speedup_vs_r = if (c_ms > 0) r_ms / c_ms else NA_real_,
          equivalent_to_r = TRUE,
          semantic_authority = "R",
          status = "reference_experimental",
          stringsAsFactors = FALSE
        )
      )
    }
    result
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
