# == Signal envelope and deterministic schedule =====================
# STATUS: reference_experimental (v0.6.2)
#
# A signal envelope is routing metadata, not payload and not meaning.
# Fast/slow and dense/sparse are explicit caller declarations.  The
# scheduler never infers biological, neural, metabolic or immune
# semantics from a token or value.

.signal_character_scalar <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x) ||
      grepl("\n|\r", x)) {
    stop(sprintf("`%s` must be one non-empty, single-line character value.",
                 name), call. = FALSE)
  }
  x
}

.signal_integer_scalar <- function(x, name, minimum = 1L) {
  if (!(is.integer(x) || is.numeric(x)) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x != trunc(x) || x < minimum ||
      x > .Machine$integer.max) {
    stop(sprintf("`%s` must be one integer >= %d.", name, minimum),
         call. = FALSE)
  }
  as.integer(x)
}

.validate_signal_envelope <- function(x) {
  if (!inherits(x, "visualr_signal_envelope")) {
    stop("`signal` must be a visualr_signal_envelope.", call. = FALSE)
  }
  required <- c(
    "source_kind", "timescale", "density", "update_interval",
    "spatial_scope", "persistence", "provenance", "uncertainty",
    "declared"
  )
  if (!identical(names(x), required)) {
    stop("Signal envelope fields are invalid.", call. = FALSE)
  }
  .signal_character_scalar(x$source_kind, "signal$source_kind")
  .signal_character_scalar(x$timescale, "signal$timescale")
  if (!x$timescale %in% c("static", "fast", "slow")) {
    stop("Signal envelope has an invalid timescale.", call. = FALSE)
  }
  .signal_character_scalar(x$density, "signal$density")
  if (!x$density %in% c("dense", "sparse")) {
    stop("Signal envelope has an invalid density.", call. = FALSE)
  }
  .signal_integer_scalar(x$update_interval, "signal$update_interval")
  .signal_character_scalar(x$spatial_scope, "signal$spatial_scope")
  .signal_character_scalar(x$persistence, "signal$persistence")
  if (!x$persistence %in% c("transient", "persistent")) {
    stop("Signal envelope has an invalid persistence.", call. = FALSE)
  }
  .signal_character_scalar(x$provenance, "signal$provenance")
  if (!is.numeric(x$uncertainty) || length(x$uncertainty) != 1L ||
      is.na(x$uncertainty) || !is.finite(x$uncertainty) ||
      x$uncertainty < 0 || x$uncertainty > 1) {
    stop("Signal envelope uncertainty must be in [0, 1].", call. = FALSE)
  }
  if (!is.logical(x$declared) || length(x$declared) != 1L ||
      is.na(x$declared)) {
    stop("Signal envelope declared flag is invalid.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Construct explicit signal-routing metadata
#' @description Declares where a numeric field came from and how often it is
#'   eligible for scheduling. This object contains no payload and performs no
#'   semantic inference. Fast/slow and dense/sparse are routing declarations,
#'   not biological or neural claims.
#' @param source_kind non-empty source identifier
#' @param timescale one of \code{"static"}, \code{"fast"}, or \code{"slow"}
#' @param density one of \code{"dense"} or \code{"sparse"}
#' @param update_interval positive integer tick interval
#' @param spatial_scope caller-declared spatial scope
#' @param persistence \code{"transient"} or \code{"persistent"}
#' @param provenance non-empty provenance identifier
#' @param uncertainty finite scalar in \code{[0,1]}; an observation field,
#'   not a correctness probability
#' @return a \code{visualr_signal_envelope}
new_signal_envelope <- function(source_kind,
                                timescale = c("static", "fast", "slow"),
                                density = c("dense", "sparse"),
                                update_interval = 1L,
                                spatial_scope = "declared",
                                persistence = c("persistent", "transient"),
                                provenance = "caller:unspecified",
                                uncertainty = 0) {
  source_kind <- .signal_character_scalar(source_kind, "source_kind")
  timescale <- tryCatch(
    match.arg(timescale, c("static", "fast", "slow")),
    error = function(e) {
      stop("`timescale` must be 'static', 'fast', or 'slow'.",
           call. = FALSE)
    }
  )
  density <- tryCatch(
    match.arg(density, c("dense", "sparse")),
    error = function(e) {
      stop("`density` must be 'dense' or 'sparse'.", call. = FALSE)
    }
  )
  update_interval <- .signal_integer_scalar(
    update_interval, "update_interval"
  )
  spatial_scope <- .signal_character_scalar(spatial_scope, "spatial_scope")
  persistence <- tryCatch(
    match.arg(persistence, c("persistent", "transient")),
    error = function(e) {
      stop("`persistence` must be 'persistent' or 'transient'.",
           call. = FALSE)
    }
  )
  provenance <- .signal_character_scalar(provenance, "provenance")
  if (!is.numeric(uncertainty) || length(uncertainty) != 1L ||
      is.na(uncertainty) || !is.finite(uncertainty) ||
      uncertainty < 0 || uncertainty > 1) {
    stop("`uncertainty` must be one finite value in [0, 1].",
         call. = FALSE)
  }

  out <- structure(
    list(
      source_kind = source_kind,
      timescale = timescale,
      density = density,
      update_interval = update_interval,
      spatial_scope = spatial_scope,
      persistence = persistence,
      provenance = provenance,
      uncertainty = as.numeric(uncertainty),
      declared = TRUE
    ),
    class = "visualr_signal_envelope"
  )
  .validate_signal_envelope(out)
  out
}

.default_signal_envelope <- function() {
  x <- new_signal_envelope(
    source_kind = "unspecified",
    timescale = "static",
    density = "dense",
    update_interval = 1L,
    spatial_scope = "declared",
    persistence = "persistent",
    provenance = "visualR:default-envelope",
    uncertainty = 0
  )
  x$declared <- FALSE
  x
}

#' @title Compile a deterministic multi-timescale signal schedule
#' @description Selects fields whose explicit update interval divides the
#'   current tick. Values are never combined or reduced. Fast routes are
#'   ordered before slow and static routes only to make execution order
#'   deterministic; this ordering is not a priority or quality claim.
#' @param fields named list of \code{visualr_numeric_field} objects
#' @param tick positive integer logical tick
#' @return a \code{visualr_signal_schedule} with active and inactive rows
compile_signal_schedule <- function(fields, tick) {
  if (!is.list(fields) || length(fields) == 0L) {
    stop("`fields` must be a non-empty list of numeric fields.",
         call. = FALSE)
  }
  tick <- .signal_integer_scalar(tick, "tick")
  field_ids <- names(fields)
  if (is.null(field_ids) || anyNA(field_ids) || any(!nzchar(field_ids)) ||
      anyDuplicated(field_ids)) {
    stop("`fields` must have unique, non-empty names.", call. = FALSE)
  }

  rows <- lapply(seq_along(fields), function(i) {
    field <- fields[[i]]
    validate_numeric_field(field)
    signal <- field$signal
    .validate_signal_envelope(signal)
    data.frame(
      field_id = field_ids[[i]],
      source_hash = field$source_hash,
      source_kind = signal$source_kind,
      timescale = signal$timescale,
      density = signal$density,
      update_interval = signal$update_interval,
      route_class = paste(signal$timescale, signal$density, sep = "_"),
      active = tick %% signal$update_interval == 0L,
      input_order = as.integer(i),
      stringsAsFactors = FALSE
    )
  })
  table <- do.call(rbind, rows)
  priority <- match(table$timescale, c("fast", "slow", "static"))
  table <- table[order(priority, table$input_order), , drop = FALSE]
  rownames(table) <- NULL

  active <- table[table$active, setdiff(names(table), "active"), drop = FALSE]
  inactive <- table[!table$active, setdiff(names(table), "active"), drop = FALSE]
  structure(
    list(
      tick = tick,
      active = active,
      inactive = inactive,
      mixed_payload = FALSE,
      status = "reference_experimental"
    ),
    class = "visualr_signal_schedule"
  )
}

#' @export
print.visualr_signal_envelope <- function(x, ...) {
  .validate_signal_envelope(x)
  cat(sprintf(
    "<visualr_signal_envelope> source=%s route=%s_%s every=%d declared=%s\n",
    x$source_kind, x$timescale, x$density, x$update_interval, x$declared
  ))
  invisible(x)
}

#' @export
print.visualr_signal_schedule <- function(x, ...) {
  cat(sprintf(
    "<visualr_signal_schedule> tick=%d active=%d inactive=%d mixed_payload=FALSE\n",
    x$tick, nrow(x$active), nrow(x$inactive)
  ))
  invisible(x)
}
