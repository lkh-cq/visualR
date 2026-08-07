# == materialize: UNIFIED carrier dispatch (P0-2) =====================
# v0.2.1 Semantic Hardening: pal_pipe / batch_compute / interact MUST
# call the SAME materialize() entry point -- one carrier dispatch, no
# semantic forks.
#
# Carriers:
#   "canonical_jiugong" -- pal_to_jiugong (S_4 3x3; perfect-square only)
#   "gamma_local"       -- gamma_field (S_k 3x3 universal)
#   "carrier_11x11"     -- S_5 carrier (experimental, P0-7)
#   "auto"              -- S_4 -> canonical_jiugong, else gamma_local
#
# P0-2 ruling: "auto" is the DEFAULT for interactive entry points so a
# given S_k always materializes to the same carrier regardless of which
# entry point called it. Explicit carrier overrides are allowed but the
# dispatch code path is shared.

#' @title Materialize a pal state to a working matrix (unified dispatch)
#' @description THE single carrier-dispatch entry point. All computation
#'   entry points (pal_pipe, batch_compute, interact) must go through
#'   this function so a given pal state always materializes identically.
#' @param pal a visualr_pal object
#' @param carrier single character: "auto" (default), "canonical_jiugong",
#'   "gamma_local", or "carrier_11x11"
#' @return list with fields: carrier (resolved name), grid (3x3 or
#'   n x n matrix), ok (logical)
#' @examples
#' materialize(new_pal_state(c("A","B","C","D"), "e"))
materialize <- function(pal, carrier = "auto") {
  validate_pal(pal)
  if (!is.character(carrier) || length(carrier) != 1L) {
    stop("`carrier` must be a single character.", call. = FALSE)
  }

  resolved <- carrier
  grid <- NULL
  ok <- TRUE

  if (carrier == "auto") {
    # S_4 (perfect-square unfolded) -> canonical jiugong; else gamma
    n <- length(unfold_pal(pal))
    k <- sqrt(n)
    if (k == floor(k) && k == 3L) {
      resolved <- "canonical_jiugong"
      grid <- pal_to_jiugong(pal)$grid
    } else {
      resolved <- "gamma_local"
      grid <- tryCatch(gamma_field(pal), error = function(e) NULL)
      if (is.null(grid)) ok <- FALSE
    }
  } else if (carrier == "canonical_jiugong") {
    grid <- tryCatch(pal_to_jiugong(pal)$grid, error = function(e) NULL)
    if (is.null(grid)) ok <- FALSE
  } else if (carrier == "gamma_local") {
    grid <- tryCatch(gamma_field(pal), error = function(e) NULL)
    if (is.null(grid)) ok <- FALSE
  } else if (carrier == "carrier_11x11") {
    grid <- tryCatch(carrier_11x11(), error = function(e) NULL)
    if (is.null(grid)) ok <- FALSE
  } else {
    stop(sprintf("Unknown carrier: '%s'. Choose auto/canonical_jiugong/gamma_local/carrier_11x11.",
                 carrier), call. = FALSE)
  }

  list(carrier = resolved, grid = grid, ok = ok)
}
