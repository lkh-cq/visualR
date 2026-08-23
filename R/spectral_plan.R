# == Explicit unitary spectral observation ==========================
# STATUS: reference_experimental (v0.6.2)
#
# A spectrum is an observation view.  Closed does not imply periodic,
# open does not imply padding, and no convolution equivalence is claimed
# unless a caller separately supplies a compatible operator contract.

.spectral_plan_hash <- function(plan) {
  digest_sha256(paste(
    plan$source_hash,
    plan$address_order_hash,
    plan$domain,
    plan$boundary_state,
    plan$boundary_policy,
    plan$normalization,
    plan$center_shift,
    paste(plan$shape, collapse = "x"),
    plan$completeness,
    plan$transform,
    sep = "|"
  ))
}

.validate_spectral_plan <- function(plan) {
  if (!inherits(plan, "visualr_spectral_plan")) {
    stop("`plan` must be a visualr_spectral_plan.", call. = FALSE)
  }
  required <- c(
    "source_hash", "address_order_hash", "domain", "boundary_state",
    "boundary_policy", "normalization", "center_shift", "shape", "n",
    "completeness", "transform", "plan_hash", "status"
  )
  if (!identical(names(plan), required)) {
    stop("Spectral plan schema is invalid.", call. = FALSE)
  }
  character_fields <- c(
    "source_hash", "address_order_hash", "domain", "boundary_state",
    "boundary_policy", "normalization", "center_shift", "completeness",
    "transform", "plan_hash", "status"
  )
  valid_character <- vapply(character_fields, function(name) {
    value <- plan[[name]]
    is.character(value) && length(value) == 1L && !is.na(value) &&
      nzchar(value)
  }, logical(1))
  if (!all(valid_character) || !is.integer(plan$shape) ||
      length(plan$shape) == 0L || anyNA(plan$shape) ||
      any(plan$shape < 1L) || !is.integer(plan$n) ||
      length(plan$n) != 1L || is.na(plan$n) || plan$n < 1L) {
    stop("Spectral plan contract is invalid.", call. = FALSE)
  }
  if (!plan$domain %in% c("path", "carrier") ||
      !plan$boundary_state %in% c("closed", "open") ||
      !plan$boundary_policy %in% c("periodic", "finite_window") ||
      !identical(plan$normalization, "unitary") ||
      !identical(plan$center_shift, "none") ||
      !identical(plan$n, as.integer(prod(plan$shape))) ||
      !identical(plan$transform, "base_R_fft") ||
      !identical(plan$status, "reference_experimental") ||
      !identical(plan$completeness,
                 if (identical(plan$boundary_state, "open"))
                   "window_only" else "complete_observation") ||
      (identical(plan$boundary_state, "open") &&
       identical(plan$boundary_policy, "periodic"))) {
    stop("Spectral plan contract is invalid.", call. = FALSE)
  }
  if (!identical(.spectral_plan_hash(plan), plan$plan_hash)) {
    stop("Spectral plan hash mismatch (fail closed).", call. = FALSE)
  }
  invisible(TRUE)
}

.spectrum_hash <- function(spectrum) {
  parts <- c(
    "visualr_spectrum_v1",
    spectrum$plan$plan_hash,
    spectrum$source_hash,
    spectrum$normalization,
    .field_encode_values(as.vector(spectrum$coefficient))
  )
  digest_sha256(paste(.field_length_prefix(parts), collapse = "|"))
}

.validate_spectrum <- function(spectrum) {
  if (!inherits(spectrum, "visualr_spectrum")) {
    stop("`spectrum` must be a visualr_spectrum.", call. = FALSE)
  }
  required <- c(
    "coefficient", "energy", "plan", "source_field", "source_hash",
    "normalization", "spectrum_hash", "status"
  )
  if (!identical(names(spectrum), required)) {
    stop("Spectrum schema is invalid.", call. = FALSE)
  }
  .validate_spectral_plan(spectrum$plan)
  validate_numeric_field(spectrum$source_field)
  if (!identical(spectrum$source_hash, spectrum$plan$source_hash) ||
      !identical(spectrum$source_hash, spectrum$source_field$source_hash) ||
      !identical(spectrum$normalization, "unitary") ||
      !is.character(spectrum$spectrum_hash) ||
      length(spectrum$spectrum_hash) != 1L ||
      is.na(spectrum$spectrum_hash) || !nzchar(spectrum$spectrum_hash) ||
      !identical(spectrum$status, "reference_experimental") ||
      !(is.numeric(spectrum$coefficient) || is.complex(spectrum$coefficient)) ||
      length(spectrum$coefficient) != spectrum$plan$n ||
      any(!is.finite(spectrum$coefficient)) ||
      !is.numeric(spectrum$energy) ||
      length(spectrum$energy) != spectrum$plan$n ||
      anyNA(spectrum$energy) || any(!is.finite(spectrum$energy)) ||
      any(spectrum$energy < 0) ||
      !isTRUE(all.equal(
        as.vector(spectrum$energy),
        as.vector(Mod(spectrum$coefficient)^2),
        tolerance = 16 * .Machine$double.eps,
        check.attributes = FALSE
      ))) {
    stop("Spectrum identity/energy contract is invalid.", call. = FALSE)
  }
  if (!identical(.spectrum_hash(spectrum), spectrum$spectrum_hash)) {
    stop("Spectrum hash mismatch (fail closed).", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Compile an explicit unitary spectral plan
#' @description Records transform shape, address order, normalization and
#'   boundary policy. A finite-window spectrum is an observation of the
#'   supplied samples only. Periodic behavior must be requested explicitly
#'   and is refused for open fields.
#' @param field a \code{visualr_numeric_field}
#' @param domain \code{"path"} or \code{"carrier"}, matching the field
#' @param boundary_policy required: \code{"finite_window"} or
#'   \code{"periodic"}
#' @param normalization only \code{"unitary"} is supported
#' @param center_shift only \code{"none"} is supported in v0.6.2
#' @return a \code{visualr_spectral_plan}
compile_spectral_plan <- function(field,
                                  domain = c("path", "carrier"),
                                  boundary_policy,
                                  normalization = "unitary",
                                  center_shift = "none") {
  validate_numeric_field(field)
  if (any(!field$mask)) {
    stop("Spectral plans require a fully observed field; masked-sample policy is undefined.",
         call. = FALSE)
  }
  domain <- match.arg(domain)
  if (missing(boundary_policy)) {
    stop("`boundary_policy` must be declared explicitly.", call. = FALSE)
  }
  boundary_policy <- match.arg(boundary_policy,
                               c("finite_window", "periodic"))
  if (!identical(domain, field$domain)) {
    stop("Spectral plan domain does not match the numeric field.",
         call. = FALSE)
  }
  if (!identical(normalization, "unitary")) {
    stop("Only unitary spectral normalization is supported.",
         call. = FALSE)
  }
  if (!identical(center_shift, "none")) {
    stop("Only center_shift = 'none' is implemented in v0.6.2.",
         call. = FALSE)
  }
  if (identical(field$boundary_state, "open") &&
      identical(boundary_policy, "periodic")) {
    stop("Periodic execution is refused for an open field.",
         call. = FALSE)
  }

  completeness <- if (identical(field$boundary_state, "open")) {
    "window_only"
  } else {
    "complete_observation"
  }
  plan <- structure(
    list(
      source_hash = field$source_hash,
      address_order_hash = digest_sha256(
        paste(field$address$address_id, collapse = "|")
      ),
      domain = domain,
      boundary_state = field$boundary_state,
      boundary_policy = boundary_policy,
      normalization = "unitary",
      center_shift = "none",
      shape = field$shape,
      n = as.integer(length(field$value)),
      completeness = completeness,
      transform = "base_R_fft",
      plan_hash = NA_character_,
      status = "reference_experimental"
    ),
    class = "visualr_spectral_plan"
  )
  plan$plan_hash <- .spectral_plan_hash(plan)
  .validate_spectral_plan(plan)
  plan
}

#' @title Execute a unitary spectral plan
#' @param field a numeric field with the source identity used by \code{plan}
#' @param plan a \code{visualr_spectral_plan}
#' @return a \code{visualr_spectrum}
execute_spectral_plan <- function(field, plan) {
  validate_numeric_field(field)
  .validate_spectral_plan(plan)
  if (!identical(field$source_hash, plan$source_hash)) {
    stop("Spectral plan source hash does not match the field.",
         call. = FALSE)
  }
  address_hash <- digest_sha256(
    paste(field$address$address_id, collapse = "|")
  )
  if (!identical(address_hash, plan$address_order_hash) ||
      !identical(field$shape, plan$shape)) {
    stop("Spectral plan address order/shape is stale.", call. = FALSE)
  }

  input <- if (length(field$shape) == 2L) {
    array(field$value, dim = field$shape)
  } else {
    field$value
  }
  coefficient <- stats::fft(input) / sqrt(plan$n)
  spectrum <- structure(
    list(
      coefficient = coefficient,
      energy = Mod(coefficient)^2,
      plan = plan,
      source_field = field,
      source_hash = field$source_hash,
      normalization = "unitary",
      spectrum_hash = NA_character_,
      status = "reference_experimental"
    ),
    class = "visualr_spectrum"
  )
  spectrum$spectrum_hash <- .spectrum_hash(spectrum)
  .validate_spectrum(spectrum)
  spectrum
}

#' @title Invert a unitary visualR spectrum
#' @param spectrum a \code{visualr_spectrum}
#' @return reconstructed \code{visualr_numeric_field}
inverse_spectral <- function(spectrum) {
  .validate_spectrum(spectrum)
  n <- spectrum$plan$n
  reconstructed <- stats::fft(spectrum$coefficient, inverse = TRUE) / sqrt(n)
  out <- spectrum$source_field
  out$value <- as.vector(reconstructed)
  out$source_hash <- .numeric_field_source_hash(out)
  validate_numeric_field(out)
  out
}

#' @title Compute direct angular Fourier modes
#' @description Computes declared weighted angular modes without polar
#'   interpolation. Center samples with undefined theta must have zero weight.
#' @param field two-dimensional numeric field
#' @param chart matching lossless polar chart
#' @param modes finite integer mode indices
#' @param weights required non-negative sampling weights
#' @return a \code{visualr_angular_modes}
angular_modes <- function(field, chart, modes, weights) {
  validate_numeric_field(field)
  .validate_polar_chart(chart)
  if (!identical(field$source_hash, chart$source_hash) ||
      !identical(field$address$address_id, chart$data$address_id)) {
    stop("Polar chart does not match the numeric field.", call. = FALSE)
  }
  if (!(is.integer(modes) || is.numeric(modes)) || length(modes) == 0L ||
      anyNA(modes) || any(!is.finite(modes)) || any(modes != trunc(modes))) {
    stop("`modes` must contain finite integers.", call. = FALSE)
  }
  modes <- as.integer(modes)
  if (missing(weights)) {
    stop("`weights` must be declared explicitly.", call. = FALSE)
  }
  if (!is.numeric(weights) || length(weights) != length(field$value) ||
      anyNA(weights) || any(!is.finite(weights)) || any(weights < 0) ||
      sum(weights) <= 0) {
    stop("`weights` must be finite, non-negative, and match the field.",
         call. = FALSE)
  }
  undefined <- is.na(chart$data$theta)
  if (any(weights[undefined] != 0)) {
    stop("Samples with undefined theta must have zero angular weight.",
         call. = FALSE)
  }
  if (any(weights[!field$mask] != 0)) {
    stop("Masked samples must have zero angular weight.", call. = FALSE)
  }
  theta <- chart$data$theta
  theta[undefined] <- 0
  coefficient <- vapply(modes, function(m) {
    sum(weights * field$value * exp(-1i * m * theta)) / sum(weights)
  }, complex(1))

  structure(
    list(
      mode = modes,
      coefficient = coefficient,
      weights = weights,
      normalization = "declared_weighted_mean",
      source_hash = field$source_hash,
      chart_hash = chart$chart_hash,
      status = "reference_experimental"
    ),
    class = "visualr_angular_modes"
  )
}

#' @export
print.visualr_spectral_plan <- function(x, ...) {
  .validate_spectral_plan(x)
  cat(sprintf(
    "<visualr_spectral_plan> domain=%s n=%d boundary=%s completeness=%s\n",
    x$domain, x$n, x$boundary_policy, x$completeness
  ))
  invisible(x)
}

#' @export
print.visualr_spectrum <- function(x, ...) {
  .validate_spectrum(x)
  cat(sprintf(
    "<visualr_spectrum> coefficients=%d normalization=%s completeness=%s\n",
    length(x$coefficient), x$normalization, x$plan$completeness
  ))
  invisible(x)
}

#' @export
print.visualr_angular_modes <- function(x, ...) {
  cat(sprintf("<visualr_angular_modes> modes=%d normalization=%s\n",
              length(x$mode), x$normalization))
  invisible(x)
}
