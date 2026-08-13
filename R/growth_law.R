# == Growth-law frozen constant table (TCN reference, D) =============
# STATUS: reference_additive (2026-08-13)
#   Not frozen semantics -- an additive reference table that makes
#   growth laws explicit, mirroring TCN's dilation = 2^i discipline:
#   the growth law is a named constant, not a formula buried in code.
#
#   visualR v0.5.0 already carries growth behavior in two places:
#     - equation_core.R : L_s = 2s+1, W_d = d+2, Q_d = 2d+2
#       (candidate_not_frozen -- deliberately NOT frozen)
#     - gradient_emerge.R : gradient_layers (layered batches)
#   This file does NOT promote or freeze those candidates. It only
#   exposes them side by side with the frozen TCN reference law so
#   that any future freeze decision is made against one table.

# Growth-law table (frozen = the law is authoritative for its source)
GROWTH_LAW_TABLE <- data.frame(
  law_id    = c("dilation_power", "gradient_batch", "carrier_width", "pal_path"),
  base      = c(2L, 1L, 1L, 2L),
  step      = c(1L, 1L, 2L, 1L),
  formula   = c("base^depth", "depth", "depth+2", "2*depth+1"),
  frozen    = c(TRUE, TRUE, FALSE, FALSE),
  source    = c("TCN dilation reference (locuslab/TCN)",
                "gradient_layers v0.5.0",
                "W_d candidate (equation_core, not frozen)",
                "L_s candidate (equation_core, not frozen)"),
  stringsAsFactors = FALSE
)

#' @title Query a growth law at a given depth
#' @description Looks up a named growth law in the frozen constant
#'   table and returns its value at the requested depth. This mirrors
#'   TCN's explicit dilation law (base^depth) and keeps visualR's own
#'   candidate laws side by side WITHOUT freezing them: the table is a
#'   single authority for comparing growth behavior.
#'
#'   Fail-closed: unknown \code{law_id} stops; non-integer or negative
#'   \code{depth} stops.
#' @param law_id character(1), one of \code{"dilation_power"},
#'   \code{"gradient_batch"}, \code{"carrier_width"}, \code{"pal_path"}.
#' @param depth integer(1) >= 0; layer/depth index (depth 0 is the
#'   first element of the sequence).
#' @return A list of class \code{visualr_growth_law} with law_id,
#'   depth, value, formula, frozen and source.
#' @examples
#' growth_law("dilation_power", depth = 3L)   # 8  (2^3)
#' growth_law("pal_path", depth = 4L)         # 9  (2*4+1, candidate)
growth_law <- function(law_id, depth) {
  if (!is.character(law_id) || length(law_id) != 1L || is.na(law_id)) {
    stop("`law_id` must be one non-NA character.", call. = FALSE)
  }
  if (!law_id %in% GROWTH_LAW_TABLE$law_id) {
    stop(sprintf("Unknown law_id %s. Known: %s.",
                 sQuote(law_id),
                 paste(GROWTH_LAW_TABLE$law_id, collapse = ", ")),
         call. = FALSE)
  }
  depth <- as.integer(depth)
  if (length(depth) != 1L || is.na(depth) || depth < 0L) {
    stop("`depth` must be one non-negative integer.", call. = FALSE)
  }

  row <- GROWTH_LAW_TABLE[GROWTH_LAW_TABLE$law_id == law_id, ]
  value <- switch(
    law_id,
    dilation_power = as.integer(row$base^depth),
    gradient_batch = as.integer(depth),
    carrier_width = as.integer(depth + row$step),
    pal_path      = as.integer(row$base * depth + row$step)
  )
  structure(
    list(
      law_id = law_id,
      depth = depth,
      value = value,
      formula = row$formula,
      frozen = row$frozen,
      source = row$source
    ),
    class = "visualr_growth_law"
  )
}

#' @export
print.visualr_growth_law <- function(x, ...) {
  cat(sprintf("<visualr_growth_law> %s depth=%d value=%d frozen=%s\n",
              x$law_id, x$depth, x$value, x$frozen))
  cat(sprintf("  formula: %s\n  source:  %s\n", x$formula, x$source))
  invisible(x)
}

#' @title Generate a growth sequence from the frozen table
#' @description Returns the first \code{depth_max + 1} values of a
#'   named growth law as an integer vector (depth 0 .. depth_max).
#'   This is the TCN-style explicit sequence (1, 2, 4, 8, ... for
#'   dilation_power) made available to any consumer that needs the
#'   law without recomputing it.
#' @param law_id character(1) as in \code{growth_law()}.
#' @param depth_max integer(1) >= 0; largest depth to include.
#' @return integer vector of length \code{depth_max + 1}.
#' @examples
#' growth_sequence("dilation_power", depth_max = 4L)  # 1 2 4 8 16
growth_sequence <- function(law_id, depth_max) {
  depth_max <- as.integer(depth_max)
  if (length(depth_max) != 1L || is.na(depth_max) || depth_max < 0L) {
    stop("`depth_max` must be one non-negative integer.", call. = FALSE)
  }
  vapply(0:depth_max, function(d) {
    growth_law(law_id, d)$value
  }, integer(1))
}
