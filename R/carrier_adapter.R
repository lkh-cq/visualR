# == Carrier transfer adapter (TCN reference, C + A) =================
# STATUS: reference_additive (2026-08-13)
#   TCN's TemporalBlock adapts channels only when they differ: same
#   channels -> identity residual (pass-through); different channels
#   -> explicit 1x1 downsample convolution. Nothing implicit.
#
#   visualR analogue: moving a PAL/compute state between carriers of
#   different width must be explicit. A non-3x3 carrier is a VIEW, not
#   a compute path (typed carrier dispatch discipline, A): the adapter
#   refuses to route a view into a compute path unless the transfer is
#   declared legal.
#
#   legal_views: 3x3 (compute path), 4x4 and 11x11 (registered views).
#   Everything else fails closed.

# Legal carrier widths: compute path + registered views
CARRIER_LEGAL_WIDTHS <- c(3L, 4L, 11L)

#' @title Adapt a square matrix between carrier widths
#' @description Transfers a square matrix between carrier widths with
#'   explicit, auditable rules. This mirrors TCN's downsample
#'   discipline: same width -> identity (pass-through, no copy of
#'   semantics); different width -> an explicit adaptation.
#'
#'   Supported adaptations (fail-closed on anything else):
#'   \itemize{
#'     \item same width: identity pass-through (match = passthrough);
#'     \item 3x3 -> 4x4: 1x1 border pad with zeros (view expansion,
#'           not a semantic transform);
#'     \item 4x4 -> 3x3: 1x1 border crop (view reduction);
#'     \item 3x3 -> 11x11: refuses by default -- 11x11 is the S_5
#'           carrier view and must be built by \code{carrier_11x11()},
#'           not by padding (typed view discipline, A).
#'   }
#' @param x numeric or character square matrix.
#' @param from_width integer(1), current carrier width.
#' @param to_width integer(1), target carrier width.
#' @return list of class \code{visualr_carrier_adapter} with adapted
#'   matrix, from_width, to_width, rule, matched.
#' @examples
#' carrier_adapter(matrix(1:9, 3L, 3L), 3L, 4L)
#' carrier_adapter(matrix(1:9, 3L, 3L), 3L, 3L)$matched  # TRUE
carrier_adapter <- function(x, from_width, to_width) {
  if (!is.matrix(x) || nrow(x) != ncol(x)) {
    stop("`x` must be a square matrix.", call. = FALSE)
  }
  from_width <- as.integer(from_width)
  to_width <- as.integer(to_width)
  if (length(from_width) != 1L || is.na(from_width) ||
      length(to_width) != 1L || is.na(to_width)) {
    stop("`from_width` and `to_width` must be single integers.",
         call. = FALSE)
  }
  if (nrow(x) != from_width) {
    stop(sprintf("`x` has width %d but `from_width` = %d.",
                 nrow(x), from_width), call. = FALSE)
  }
  if (!from_width %in% CARRIER_LEGAL_WIDTHS ||
      !to_width %in% CARRIER_LEGAL_WIDTHS) {
    stop(sprintf(
      "Illegal carrier width. Legal widths: %s. Got from=%d to=%d.",
      paste(CARRIER_LEGAL_WIDTHS, collapse = ", "),
      from_width, to_width), call. = FALSE)
  }

  matched <- from_width == to_width
  if (matched) {
    out <- x
    rule <- "identity_pass_through"
  } else if (from_width == 3L && to_width == 4L) {
    out <- pad_bottom_right(x, pad = 0L)
    rule <- "border_pad_3to4"
  } else if (from_width == 4L && to_width == 3L) {
    out <- x[1:(nrow(x) - 1L), 1:(ncol(x) - 1L), drop = FALSE]
    rule <- "border_crop_4to3"
  } else {
    stop(sprintf(
      paste0("Refusing carrier transfer %dx%d -> %dx%d: this transfer ",
             "is not a legal view adaptation. 11x11 is the S_5 carrier ",
             "view and must be built by carrier_11x11(), not by padding ",
             "(typed view discipline)."),
      from_width, from_width, to_width, to_width), call. = FALSE)
  }

  structure(
    list(
      adapted = out,
      from_width = from_width,
      to_width = to_width,
      rule = rule,
      matched = matched
    ),
    class = "visualr_carrier_adapter"
  )
}

#' @export
print.visualr_carrier_adapter <- function(x, ...) {
  cat(sprintf("<visualr_carrier_adapter> %dx%d -> %dx%d rule=%s matched=%s\n",
              x$from_width, x$from_width, x$to_width, x$to_width,
              x$rule, x$matched))
  invisible(x)
}

# Internal: pad a square matrix by appending one zero row and one zero
# column (bottom + right), growing the width by exactly one.
pad_bottom_right <- function(x, pad) {
  n <- nrow(x)
  out <- matrix(pad, nrow = n + 1L, ncol = n + 1L)
  out[1:n, 1:n] <- x
  out
}
