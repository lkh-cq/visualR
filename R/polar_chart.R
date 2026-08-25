# == Lossless polar observation chart ===============================
# STATUS: reference_experimental (v0.6.2)
#
# The chart appends r/theta coordinates to existing carrier addresses.
# It never replaces row/column identity and performs no interpolation.

.polar_topology_centers <- function(nr, nc) {
  rows <- if (nr %% 2L == 1L) (nr + 1L) / 2L else c(nr / 2L, nr / 2L + 1L)
  cols <- if (nc %% 2L == 1L) (nc + 1L) / 2L else c(nc / 2L, nc / 2L + 1L)
  centers <- expand.grid(row = rows, col = cols)
  centers$row <- as.numeric(centers$row)
  centers$col <- as.numeric(centers$col)
  centers
}

.polar_chart_hash <- function(data, source_hash) {
  encoded <- c(
    data$address_id,
    as.character(data$row),
    as.character(data$col),
    .field_encode_values(data$value),
    .field_encode_values(data$x),
    .field_encode_values(data$y),
    .field_encode_values(data$r),
    .field_encode_values(ifelse(is.na(data$theta), -Inf, data$theta)),
    .field_encode_values(data$manhattan_r),
    .field_encode_values(data$chebyshev_r)
  )
  digest_sha256(paste(source_hash, paste(encoded, collapse = "|"), sep = "|"))
}

.validate_polar_chart <- function(chart) {
  if (!inherits(chart, "visualr_polar_chart")) {
    stop("`chart` must be a visualr_polar_chart.", call. = FALSE)
  }
  required <- c(
    "data", "geometric_center", "topology_centers", "theta_zero",
    "theta_direction", "theta_unit", "resampled", "source_hash",
    "chart_hash", "status"
  )
  if (!identical(names(chart), required) || !is.data.frame(chart$data)) {
    stop("Polar chart schema is invalid.", call. = FALSE)
  }
  if (!identical(names(chart$data), c(
    "address_id", "row", "col", "value", "x", "y", "r", "theta",
    "manhattan_r", "chebyshev_r"
  ))) {
    stop("Polar chart data columns are invalid.", call. = FALSE)
  }
  numeric_columns <- c("row", "col", "x", "y", "r", "theta",
                       "manhattan_r", "chebyshev_r")
  if (nrow(chart$data) == 0L ||
      !is.character(chart$data$address_id) ||
      anyNA(chart$data$address_id) || any(!nzchar(chart$data$address_id)) ||
      anyDuplicated(chart$data$address_id) ||
      !(is.numeric(chart$data$value) || is.complex(chart$data$value)) ||
      any(!is.finite(chart$data$value)) ||
      any(!vapply(chart$data[numeric_columns], is.numeric, logical(1))) ||
      anyNA(chart$data[setdiff(numeric_columns, "theta")]) ||
      any(!is.finite(as.matrix(
        chart$data[setdiff(numeric_columns, "theta")]
      ))) ||
      any(!is.na(chart$data$theta) & !is.finite(chart$data$theta)) ||
      any(!is.na(chart$data$theta) &
          (chart$data$theta < 0 | chart$data$theta >= 2 * pi)) ||
      any(is.na(chart$data$theta) != (chart$data$r == 0)) ||
      !identical(chart$resampled, FALSE) ||
      !identical(chart$theta_zero, "positive_col_axis") ||
      !identical(chart$theta_direction,
                 "counterclockwise_with_row_axis_up") ||
      !identical(chart$theta_unit, "radian") ||
      !is.character(chart$source_hash) || length(chart$source_hash) != 1L ||
      is.na(chart$source_hash) || !nzchar(chart$source_hash)) {
    stop("Polar chart address/resampling invariant failed.", call. = FALSE)
  }
  nr <- max(chart$data$row)
  nc <- max(chart$data$col)
  expected_center <- c(row = (nr + 1) / 2, col = (nc + 1) / 2)
  if (!identical(chart$geometric_center, expected_center) ||
      !identical(chart$topology_centers,
                 .polar_topology_centers(nr, nc)) ||
      !is.character(chart$chart_hash) || length(chart$chart_hash) != 1L ||
      is.na(chart$chart_hash) || !nzchar(chart$chart_hash) ||
      !identical(chart$status, "reference_experimental")) {
    stop("Polar chart center/identity metadata is invalid.", call. = FALSE)
  }
  expected <- .polar_chart_hash(chart$data, chart$source_hash)
  if (!identical(expected, chart$chart_hash)) {
    stop("Polar chart hash mismatch (fail closed).", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Build a lossless polar observation chart
#' @description Adds geometric polar coordinates to a two-dimensional
#'   numeric field while preserving every source address and value. The
#'   geometric center and topology center set are separate fields. No
#'   interpolation or resampling is implemented in v0.6.2.
#' @param field a two-dimensional \code{visualr_numeric_field}
#' @param resample must be \code{FALSE}; \code{TRUE} fails closed
#' @return a \code{visualr_polar_chart}
polar_chart <- function(field, resample = FALSE) {
  validate_numeric_field(field)
  if (!is.logical(resample) || length(resample) != 1L || is.na(resample)) {
    stop("`resample` must be one logical value.", call. = FALSE)
  }
  if (resample) {
    stop("Polar resampling is not implemented; no interpolation contract exists.",
         call. = FALSE)
  }
  if (!identical(field$domain, "carrier") || length(field$shape) != 2L) {
    stop("`polar_chart()` requires a two-dimensional carrier field.",
         call. = FALSE)
  }

  nr <- field$shape[[1L]]
  nc <- field$shape[[2L]]
  geometric_center <- c(row = (nr + 1) / 2, col = (nc + 1) / 2)
  x <- field$address$col - geometric_center[["col"]]
  y <- geometric_center[["row"]] - field$address$row
  radius <- sqrt(x^2 + y^2)
  theta <- atan2(y, x)
  theta[theta < 0] <- theta[theta < 0] + 2 * pi
  theta[radius == 0] <- NA_real_

  data <- data.frame(
    address_id = field$address$address_id,
    row = field$address$row,
    col = field$address$col,
    value = field$value,
    x = as.numeric(x),
    y = as.numeric(y),
    r = as.numeric(radius),
    theta = as.numeric(theta),
    manhattan_r = as.numeric(abs(x) + abs(y)),
    chebyshev_r = as.numeric(pmax(abs(x), abs(y))),
    stringsAsFactors = FALSE
  )
  chart_hash <- .polar_chart_hash(data, field$source_hash)
  chart <- structure(
    list(
      data = data,
      geometric_center = geometric_center,
      topology_centers = .polar_topology_centers(nr, nc),
      theta_zero = "positive_col_axis",
      theta_direction = "counterclockwise_with_row_axis_up",
      theta_unit = "radian",
      resampled = FALSE,
      source_hash = field$source_hash,
      chart_hash = chart_hash,
      status = "reference_experimental"
    ),
    class = "visualr_polar_chart"
  )
  .validate_polar_chart(chart)
  chart
}

#' @export
print.visualr_polar_chart <- function(x, ...) {
  .validate_polar_chart(x)
  cat(sprintf(
    "<visualr_polar_chart> addresses=%d center=(%s,%s) resampled=FALSE\n",
    nrow(x$data), x$geometric_center[["row"]],
    x$geometric_center[["col"]]
  ))
  invisible(x)
}
