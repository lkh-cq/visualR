# == Address-aware numerical gradients =============================
# STATUS: reference_experimental (v0.6.2)
#
# Gradients are derived observations over declared numeric values.  A
# path derivative follows global PAL address order.  A carrier gradient
# uses caller-declared row/column spacing and one-sided boundary
# differences; no hidden padding or periodic continuation is introduced.

.real_field_values <- function(field) {
  validate_numeric_field(field)
  if (is.complex(field$value)) {
    if (any(Im(field$value) != 0)) {
      stop("Field gradients require real-valued observations.",
           call. = FALSE)
    }
    return(Re(field$value))
  }
  as.numeric(field$value)
}

.gradient_spacing <- function(spacing, domain) {
  expected <- if (identical(domain, "path")) "address" else c("row", "col")
  if (is.null(spacing)) {
    return(stats::setNames(rep.int(1, length(expected)), expected))
  }
  if (!is.numeric(spacing) || length(spacing) != length(expected) ||
      anyNA(spacing) || any(!is.finite(spacing)) || any(spacing <= 0)) {
    stop(sprintf(
      "`spacing` must contain %d finite positive value%s for %s gradients.",
      length(expected), if (length(expected) == 1L) "" else "s", domain
    ), call. = FALSE)
  }
  if (!is.null(names(spacing)) && !identical(names(spacing), expected)) {
    stop(sprintf("Named `spacing` must use: %s.",
                 paste(expected, collapse = ", ")), call. = FALSE)
  }
  stats::setNames(as.numeric(spacing), expected)
}

.gradient_mask_policy <- function(masked_policy) {
  if (!is.character(masked_policy) || length(masked_policy) != 1L ||
      is.na(masked_policy) || !identical(masked_policy, "refuse")) {
    stop("Only masked_policy = 'refuse' is implemented in v0.6.2.",
         call. = FALSE)
  }
  masked_policy
}

.axis_difference <- function(x, axis, step) {
  nr <- nrow(x)
  nc <- ncol(x)
  out <- matrix(0, nrow = nr, ncol = nc)

  if (identical(axis, "row")) {
    if (nr == 1L) return(out)
    out[1L, ] <- (x[2L, ] - x[1L, ]) / step
    out[nr, ] <- (x[nr, ] - x[nr - 1L, ]) / step
    if (nr > 2L) {
      out[2L:(nr - 1L), ] <-
        (x[3L:nr, , drop = FALSE] - x[1L:(nr - 2L), , drop = FALSE]) /
        (2 * step)
    }
  } else {
    if (nc == 1L) return(out)
    out[, 1L] <- (x[, 2L] - x[, 1L]) / step
    out[, nc] <- (x[, nc] - x[, nc - 1L]) / step
    if (nc > 2L) {
      out[, 2L:(nc - 1L)] <-
        (x[, 3L:nc, drop = FALSE] - x[, 1L:(nc - 2L), drop = FALSE]) /
        (2 * step)
    }
  }
  out
}

.field_gradient_hash <- function(gradient) {
  table <- if (identical(gradient$domain, "path")) {
    gradient$edges
  } else {
    gradient$data
  }
  table_parts <- unlist(lapply(names(table), function(name) {
    value <- table[[name]]
    encoded <- if (is.numeric(value) || is.complex(value)) {
      .field_encode_values(value)
    } else {
      ifelse(is.na(value), "<NA>", as.character(value))
    }
    c(name, encoded)
  }), use.names = FALSE)
  parts <- c(
    "visualr_field_gradient_v2",
    gradient$domain,
    gradient$source_hash,
    if (is.na(gradient$chart_hash)) "<NA>" else gradient$chart_hash,
    names(gradient$spacing),
    .field_encode_values(gradient$spacing),
    gradient$mask_policy,
    gradient$difference_policy,
    table_parts
  )
  digest_sha256(paste(.field_length_prefix(parts), collapse = "|"))
}

.validate_field_gradient <- function(gradient) {
  if (!inherits(gradient, "visualr_field_gradient")) {
    stop("`gradient` must be a visualr_field_gradient.", call. = FALSE)
  }
  required <- c(
    "domain", "data", "edges", "source_hash", "chart_hash", "spacing",
    "mask_policy", "difference_policy", "gradient_hash", "status"
  )
  if (!identical(names(gradient), required) ||
      !is.character(gradient$domain) || length(gradient$domain) != 1L ||
      is.na(gradient$domain) ||
      !gradient$domain %in% c("path", "carrier") ||
      !is.character(gradient$source_hash) ||
      length(gradient$source_hash) != 1L || is.na(gradient$source_hash) ||
      !nzchar(gradient$source_hash) ||
      !is.character(gradient$chart_hash) ||
      length(gradient$chart_hash) != 1L ||
      (!is.na(gradient$chart_hash) && !nzchar(gradient$chart_hash)) ||
      !is.character(gradient$gradient_hash) ||
      length(gradient$gradient_hash) != 1L ||
      is.na(gradient$gradient_hash) || !nzchar(gradient$gradient_hash) ||
      !identical(gradient$mask_policy, "refuse") ||
      !identical(gradient$status, "reference_experimental")) {
    stop("Field gradient schema is invalid.", call. = FALSE)
  }
  if (identical(gradient$domain, "path")) {
    columns <- c(
      "from_address_id", "to_address_id", "from_global", "to_global",
      "address_delta", "coordinate_delta", "gradient"
    )
    if (!is.null(gradient$data) || !is.data.frame(gradient$edges) ||
        !identical(names(gradient$edges), columns) ||
        anyNA(gradient$edges) ||
        any(!is.finite(gradient$edges$gradient)) ||
        any(gradient$edges$address_delta <= 0) ||
        any(gradient$edges$coordinate_delta <= 0) ||
        !identical(gradient$spacing,
                   .gradient_spacing(gradient$spacing, "path")) ||
        !isTRUE(all.equal(
          gradient$edges$coordinate_delta,
          gradient$edges$address_delta * unname(gradient$spacing[[1L]]),
          tolerance = 16 * .Machine$double.eps,
          check.attributes = FALSE
        )) ||
        !is.na(gradient$chart_hash) ||
        !identical(gradient$difference_policy,
                   "forward_over_global_address")) {
      stop("Path gradient contract is invalid.", call. = FALSE)
    }
  } else {
    columns <- c(
      "address_id", "row", "col", "g_row", "g_col", "magnitude",
      "radial", "tangential"
    )
    finite_columns <- c("g_row", "g_col", "magnitude")
    if (!is.null(gradient$edges) || !is.data.frame(gradient$data) ||
        !identical(names(gradient$data), columns) ||
        nrow(gradient$data) == 0L ||
        anyNA(gradient$data[c("address_id", "row", "col")]) ||
        any(!is.finite(as.matrix(gradient$data[finite_columns]))) ||
        any(gradient$data$magnitude < 0) ||
        !isTRUE(all.equal(
          gradient$data$magnitude,
          sqrt(gradient$data$g_row^2 + gradient$data$g_col^2),
          tolerance = 16 * .Machine$double.eps,
          check.attributes = FALSE
        )) ||
        any(!is.na(gradient$data$radial) &
            !is.finite(gradient$data$radial)) ||
        any(!is.na(gradient$data$tangential) &
            !is.finite(gradient$data$tangential)) ||
        !identical(gradient$spacing,
                   .gradient_spacing(gradient$spacing, "carrier")) ||
        !identical(is.na(gradient$data$radial),
                   is.na(gradient$data$tangential)) ||
        !identical(gradient$difference_policy,
                   "central_interior_one_sided_boundary")) {
      stop("Carrier gradient contract is invalid.", call. = FALSE)
    }
    defined <- !is.na(gradient$data$radial)
    if (any(defined) && !isTRUE(all.equal(
      sqrt(gradient$data$radial[defined]^2 +
           gradient$data$tangential[defined]^2),
      gradient$data$magnitude[defined],
      tolerance = sqrt(.Machine$double.eps),
      check.attributes = FALSE
    ))) {
      stop("Carrier polar-gradient projection is invalid.", call. = FALSE)
    }
    if ((is.na(gradient$chart_hash) &&
         any(!is.na(gradient$data$radial))) ||
        (is.na(gradient$chart_hash) &&
         any(!is.na(gradient$data$tangential)))) {
      stop("Carrier gradient chart identity is invalid.", call. = FALSE)
    }
  }
  if (!identical(.field_gradient_hash(gradient), gradient$gradient_hash)) {
    stop("Field gradient hash mismatch (fail closed).", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Compute an address-aware numeric field gradient
#' @description For carrier fields, computes finite differences with declared
#'   row/column spacing, central differences in the interior and one-sided
#'   differences at the observed boundary. For path fields, computes forward
#'   differences in strictly increasing global-address order. No padding,
#'   wraparound, or extrapolation is performed.
#' @param field a real-valued \code{visualr_numeric_field}
#' @param chart optional matching \code{visualr_polar_chart}; when supplied,
#'   radial and tangential components are added without resampling
#' @param spacing coordinate step: one positive value for a path or
#'   two positive values in row/column order for a carrier; defaults to one
#' @param masked_policy only \code{"refuse"} is implemented; masked-neighbour
#'   imputation is never inferred
#' @return a \code{visualr_field_gradient}
field_gradient <- function(field, chart = NULL, spacing = NULL,
                           masked_policy = "refuse") {
  values <- .real_field_values(field)
  masked_policy <- .gradient_mask_policy(masked_policy)
  if (any(!field$mask)) {
    stop("Field gradients require a fully observed field under masked_policy = 'refuse'.",
         call. = FALSE)
  }

  if (identical(field$domain, "path")) {
    spacing <- .gradient_spacing(spacing, "path")
    if (!is.null(chart)) {
      stop("Path gradients do not accept a two-dimensional polar chart.",
           call. = FALSE)
    }
    global <- field$address$global_address
    if (anyNA(global) || anyDuplicated(global) || is.unsorted(global,
                                                               strictly = TRUE)) {
      stop("Path gradients require unique, increasing global addresses.",
           call. = FALSE)
    }
    delta <- diff(global)
    coordinate_delta <- delta * unname(spacing[[1L]])
    edges <- data.frame(
      from_address_id = utils::head(field$address$address_id, -1L),
      to_address_id = utils::tail(field$address$address_id, -1L),
      from_global = utils::head(global, -1L),
      to_global = utils::tail(global, -1L),
      address_delta = delta,
      coordinate_delta = coordinate_delta,
      gradient = diff(values) / coordinate_delta,
      stringsAsFactors = FALSE
    )
    out <- structure(
      list(
        domain = "path",
        data = NULL,
        edges = edges,
        source_hash = field$source_hash,
        chart_hash = NA_character_,
        spacing = spacing,
        mask_policy = masked_policy,
        difference_policy = "forward_over_global_address",
        gradient_hash = NA_character_,
        status = "reference_experimental"
      ),
      class = "visualr_field_gradient"
    )
    out$gradient_hash <- .field_gradient_hash(out)
    .validate_field_gradient(out)
    return(out)
  }

  if (!identical(field$domain, "carrier") || length(field$shape) != 2L) {
    stop("Carrier gradients require a two-dimensional numeric field.",
         call. = FALSE)
  }
  spacing <- .gradient_spacing(spacing, "carrier")
  x <- matrix(values, nrow = field$shape[[1L]],
              ncol = field$shape[[2L]])
  g_row <- .axis_difference(x, "row", spacing[["row"]])
  g_col <- .axis_difference(x, "col", spacing[["col"]])
  magnitude <- sqrt(g_row^2 + g_col^2)
  radial <- tangential <- rep.int(NA_real_, length(values))
  chart_hash <- NA_character_

  if (!is.null(chart)) {
    .validate_polar_chart(chart)
    if (!identical(chart$source_hash, field$source_hash) ||
        !identical(chart$data$address_id, field$address$address_id)) {
      stop("Polar chart does not match the numeric field.", call. = FALSE)
    }
    theta <- chart$data$theta
    defined <- !is.na(theta)
    gx <- as.vector(g_col)
    gy <- -as.vector(g_row)
    radial[defined] <- gx[defined] * cos(theta[defined]) +
      gy[defined] * sin(theta[defined])
    tangential[defined] <- -gx[defined] * sin(theta[defined]) +
      gy[defined] * cos(theta[defined])
    chart_hash <- chart$chart_hash
  }

  data <- data.frame(
    address_id = field$address$address_id,
    row = field$address$row,
    col = field$address$col,
    g_row = as.vector(g_row),
    g_col = as.vector(g_col),
    magnitude = as.vector(magnitude),
    radial = radial,
    tangential = tangential,
    stringsAsFactors = FALSE
  )
  out <- structure(
    list(
      domain = "carrier",
      data = data,
      edges = NULL,
      source_hash = field$source_hash,
      chart_hash = chart_hash,
      spacing = spacing,
      mask_policy = masked_policy,
      difference_policy = "central_interior_one_sided_boundary",
      gradient_hash = NA_character_,
      status = "reference_experimental"
    ),
    class = "visualr_field_gradient"
  )
  out$gradient_hash <- .field_gradient_hash(out)
  .validate_field_gradient(out)
  out
}

#' @export
print.visualr_field_gradient <- function(x, ...) {
  .validate_field_gradient(x)
  count <- if (identical(x$domain, "path")) nrow(x$edges) else nrow(x$data)
  cat(sprintf("<visualr_field_gradient> domain=%s observations=%d policy=%s\n",
              x$domain, count, x$difference_policy))
  cat(sprintf("  spacing=%s mask_policy=%s\n",
              paste(names(x$spacing), format(x$spacing), sep = "=",
                    collapse = ","),
              x$mask_policy))
  invisible(x)
}
