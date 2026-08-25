# == Structural bias evidence and robust review gate ================
# STATUS: reference_experimental (v0.6.2)
#
# These functions expose inspectable bias indicators.  They do not emit a
# prediction probability.  A probability model remains gated on an explicit
# target definition, labelled data, temporal separation and calibration.

.validate_bias_features <- function(features, name = "features") {
  if (!is.numeric(features) || length(features) == 0L ||
      is.null(names(features)) || anyNA(names(features)) ||
      any(!nzchar(names(features))) || anyDuplicated(names(features)) ||
      anyNA(features) || any(!is.finite(features))) {
    stop(sprintf("`%s` must be a finite named numeric vector.", name),
         call. = FALSE)
  }
  invisible(TRUE)
}

.spectrum_matches <- function(spectrum, field) {
  .validate_spectrum(spectrum)
  if (!identical(spectrum$source_hash, field$source_hash)) {
    stop("Spectrum does not match the numeric field.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Extract explicit structural-bias evidence
#' @description Returns named, auditable indicators. Boundary incompleteness,
#'   masked coverage and declared source uncertainty are always present.
#'   Optional polar, spectral, and gradient summaries remain separate
#'   components. The result is evidence, not a probability or learned
#'   prediction.
#' @param field a \code{visualr_numeric_field}
#' @param chart optional matching \code{visualr_polar_chart}
#' @param spectrum optional matching \code{visualr_spectrum}
#' @param gradient optional matching \code{visualr_field_gradient}
#' @return a finite named numeric vector
bias_features <- function(field, chart = NULL, spectrum = NULL,
                          gradient = NULL) {
  validate_numeric_field(field)
  out <- c(
    B_boundary = as.numeric(identical(field$boundary_state, "open")),
    B_coverage = mean(!field$mask),
    B_uncertainty = field$signal$uncertainty
  )

  if (identical(field$domain, "carrier") && length(field$shape) == 2L) {
    nr <- field$shape[[1L]]
    nc <- field$shape[[2L]]
    center_rows <- if (nr %% 2L == 1L) (nr + 1L) / 2L else
      c(nr / 2L, nr / 2L + 1L)
    center_cols <- if (nc %% 2L == 1L) (nc + 1L) / 2L else
      c(nc / 2L, nc / 2L + 1L)
    center <- field$address$row %in% center_rows &
      field$address$col %in% center_cols
    visible <- field$mask
    baseline <- if (any(visible)) mean(Mod(field$value[visible])) else 0
    center_level <- if (any(center & visible)) {
      mean(Mod(field$value[center & visible]))
    } else {
      0
    }
    out <- c(out, B_center = abs(center_level - baseline))
  }

  if (!is.null(chart)) {
    .validate_polar_chart(chart)
    if (!identical(chart$source_hash, field$source_hash) ||
        !identical(chart$data$address_id, field$address$address_id)) {
      stop("Polar chart does not match the numeric field.", call. = FALSE)
    }
    visible <- field$mask & !is.na(chart$data$theta)
    polar <- if (sum(visible) < 2L) {
      0
    } else {
      weights <- Mod(field$value[visible])
      if (sum(weights) == 0) 0 else
        Mod(sum(weights * exp(1i * chart$data$theta[visible]))) / sum(weights)
    }
    out <- c(out, B_polar = as.numeric(polar))
  }

  if (!is.null(spectrum)) {
    .spectrum_matches(spectrum, field)
    energy <- as.vector(spectrum$energy)
    spectral <- if (sum(energy) == 0) 0 else max(energy) / sum(energy)
    out <- c(out, B_spectral = as.numeric(spectral))
  }
  if (!is.null(gradient)) {
    .validate_field_gradient(gradient)
    if (!identical(gradient$source_hash, field$source_hash) ||
        !identical(gradient$domain, field$domain)) {
      stop("Gradient does not match the numeric field.", call. = FALSE)
    }
    gradient_values <- if (identical(gradient$domain, "carrier")) {
      gradient$data$magnitude
    } else {
      abs(gradient$edges$gradient)
    }
    gradient_level <- if (length(gradient_values) == 0L) 0 else
      sqrt(mean(gradient_values^2))
    out <- c(out, B_gradient = as.numeric(gradient_level))
  }
  .validate_bias_features(out)
  out
}

.robust_feature_scale <- function(x) {
  center <- stats::median(x)
  scale <- stats::mad(x, center = center, constant = 1.4826)
  if (!is.finite(scale) || scale <= sqrt(.Machine$double.eps)) {
    scale <- stats::IQR(x, type = 8) / 1.349
  }
  if (!is.finite(scale) || scale <= sqrt(.Machine$double.eps)) {
    scale <- max(abs(x - center))
  }
  if (!is.finite(scale) || scale <= sqrt(.Machine$double.eps)) scale <- 1
  c(center = center, scale = scale)
}

.bias_threshold_hash <- function(threshold) {
  parts <- c(
    "visualr_bias_threshold_v1",
    threshold$feature_names,
    .field_encode_values(threshold$center),
    .field_encode_values(threshold$scale),
    .field_encode_values(c(threshold$alpha, threshold$threshold)),
    threshold$aggregation,
    as.character(threshold$reference_n),
    as.character(threshold$probability_calibrated)
  )
  digest_sha256(paste(.field_length_prefix(parts), collapse = "|"))
}

.validate_bias_threshold <- function(threshold) {
  if (!inherits(threshold, "visualr_bias_threshold")) {
    stop("`threshold` must be a visualr_bias_threshold.", call. = FALSE)
  }
  required <- c(
    "feature_names", "center", "scale", "alpha", "threshold",
    "aggregation", "reference_n", "target_definition",
    "probability_calibrated", "threshold_hash", "status"
  )
  if (!identical(names(threshold), required) ||
      !is.character(threshold$feature_names) ||
      length(threshold$feature_names) == 0L ||
      anyNA(threshold$feature_names) ||
      any(!nzchar(threshold$feature_names)) ||
      anyDuplicated(threshold$feature_names) ||
      !is.numeric(threshold$center) || !is.numeric(threshold$scale) ||
      !identical(names(threshold$center), threshold$feature_names) ||
      !identical(names(threshold$scale), threshold$feature_names) ||
      anyNA(threshold$center) || any(!is.finite(threshold$center)) ||
      anyNA(threshold$scale) || any(!is.finite(threshold$scale)) ||
      any(threshold$scale <= 0) ||
      !is.numeric(threshold$threshold) || length(threshold$threshold) != 1L ||
      is.na(threshold$threshold) || !is.finite(threshold$threshold) ||
      threshold$threshold < 0 ||
      !is.numeric(threshold$alpha) || length(threshold$alpha) != 1L ||
      is.na(threshold$alpha) || !is.finite(threshold$alpha) ||
      threshold$alpha <= 0 || threshold$alpha >= 0.5 ||
      !is.integer(threshold$reference_n) ||
      length(threshold$reference_n) != 1L ||
      is.na(threshold$reference_n) || threshold$reference_n < 3L ||
      !identical(threshold$aggregation, "max_absolute_robust_score") ||
      !identical(threshold$target_definition, NULL) ||
      !identical(threshold$probability_calibrated, FALSE) ||
      !is.character(threshold$threshold_hash) ||
      length(threshold$threshold_hash) != 1L ||
      is.na(threshold$threshold_hash) || !nzchar(threshold$threshold_hash) ||
      !identical(threshold$status, "reference_experimental")) {
    stop("Bias threshold contract is invalid.", call. = FALSE)
  }
  if (!identical(.bias_threshold_hash(threshold),
                 threshold$threshold_hash)) {
    stop("Bias threshold hash mismatch (fail closed).", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Fit a robust reference review threshold
#' @description Fits component-wise median/MAD-style normalization and a
#'   quantile gate over the maximum absolute component score. This is a
#'   descriptive reference gate, not supervised learning and not calibrated
#'   probability estimation.
#' @param reference data frame or numeric matrix with observations in rows
#'   and named evidence components in columns
#' @param alpha tail fraction in \code{(0, 0.5)}
#' @return a \code{visualr_bias_threshold}
fit_reference_threshold <- function(reference, alpha = 0.05) {
  if (!(is.data.frame(reference) || is.matrix(reference)) ||
      nrow(reference) < 3L) {
    stop("`reference` must contain at least three observations.",
         call. = FALSE)
  }
  reference <- as.data.frame(reference, stringsAsFactors = FALSE)
  if (ncol(reference) == 0L || is.null(names(reference)) ||
      any(!nzchar(names(reference))) || anyDuplicated(names(reference)) ||
      any(!vapply(reference, is.numeric, logical(1))) ||
      anyNA(reference) || any(!is.finite(as.matrix(reference)))) {
    stop("Reference features must be finite, numeric, and uniquely named.",
         call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) ||
      !is.finite(alpha) || alpha <= 0 || alpha >= 0.5) {
    stop("`alpha` must be one finite value in (0, 0.5).", call. = FALSE)
  }

  parameters <- t(vapply(reference, .robust_feature_scale,
                         numeric(2)))
  rownames(parameters) <- names(reference)
  normalized <- sweep(as.matrix(reference), 2L,
                      parameters[, "center"], "-")
  normalized <- sweep(normalized, 2L, parameters[, "scale"], "/")
  scores <- apply(abs(normalized), 1L, max)
  threshold <- unname(stats::quantile(scores, probs = 1 - alpha,
                                      names = FALSE, type = 8))

  out <- structure(
    list(
      feature_names = names(reference),
      center = stats::setNames(parameters[, "center"], names(reference)),
      scale = stats::setNames(parameters[, "scale"], names(reference)),
      alpha = as.numeric(alpha),
      threshold = as.numeric(threshold),
      aggregation = "max_absolute_robust_score",
      reference_n = as.integer(nrow(reference)),
      target_definition = NULL,
      probability_calibrated = FALSE,
      threshold_hash = NA_character_,
      status = "reference_experimental"
    ),
    class = "visualr_bias_threshold"
  )
  out$threshold_hash <- .bias_threshold_hash(out)
  .validate_bias_threshold(out)
  out
}

.validate_bias_audit <- function(audit) {
  if (!inherits(audit, "visualr_bias_audit")) {
    stop("`audit` must be a visualr_bias_audit.", call. = FALSE)
  }
  required <- c(
    "features", "component_score", "aggregate", "threshold", "action",
    "probability", "probability_status", "status"
  )
  if (!identical(names(audit), required)) {
    stop("Bias audit schema is invalid.", call. = FALSE)
  }
  .validate_bias_features(audit$features, "audit$features")
  if (!is.numeric(audit$component_score) ||
      !identical(names(audit$component_score), names(audit$features)) ||
      anyNA(audit$component_score) ||
      any(!is.finite(audit$component_score)) ||
      any(audit$component_score < 0) ||
      !is.numeric(audit$aggregate) || length(audit$aggregate) != 1L ||
      is.na(audit$aggregate) || !is.finite(audit$aggregate) ||
      !isTRUE(all.equal(audit$aggregate, max(audit$component_score))) ||
      !is.numeric(audit$threshold) || length(audit$threshold) != 1L ||
      is.na(audit$threshold) || !is.finite(audit$threshold) ||
      audit$threshold < 0 ||
      !identical(audit$action,
                 if (audit$aggregate > audit$threshold) "review" else
                   "within_reference") ||
      !identical(audit$probability, NULL) ||
      !identical(audit$probability_status,
                 "not_estimated_missing_supervised_calibration") ||
      !identical(audit$status, "reference_experimental")) {
    stop("Bias audit contract is invalid.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Audit evidence against a fitted reference gate
#' @param features finite named evidence vector with exactly the fitted names
#' @param threshold a \code{visualr_bias_threshold}
#' @return a \code{visualr_bias_audit}; never a probability
audit_bias <- function(features, threshold) {
  .validate_bias_features(features)
  .validate_bias_threshold(threshold)
  if (!identical(names(features), threshold$feature_names)) {
    stop("Bias feature names/order differ from the reference gate.",
         call. = FALSE)
  }
  component_score <- abs((features - threshold$center) / threshold$scale)
  aggregate <- max(component_score)
  action <- if (aggregate > threshold$threshold) "review" else
    "within_reference"
  out <- structure(
    list(
      features = features,
      component_score = component_score,
      aggregate = as.numeric(aggregate),
      threshold = threshold$threshold,
      action = action,
      probability = NULL,
      probability_status = "not_estimated_missing_supervised_calibration",
      status = "reference_experimental"
    ),
    class = "visualr_bias_audit"
  )
  .validate_bias_audit(out)
  out
}

#' @export
print.visualr_bias_threshold <- function(x, ...) {
  .validate_bias_threshold(x)
  cat(sprintf("<visualr_bias_threshold> n=%d alpha=%s threshold=%s probability=FALSE\n",
              x$reference_n, format(x$alpha), format(x$threshold)))
  invisible(x)
}

#' @export
print.visualr_bias_audit <- function(x, ...) {
  .validate_bias_audit(x)
  cat(sprintf("<visualr_bias_audit> action=%s score=%s threshold=%s probability=NULL\n",
              x$action, format(x$aggregate), format(x$threshold)))
  invisible(x)
}
