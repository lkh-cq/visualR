# == v0.8 Geometry Base — PositionState ============================
# Status: NEW (v0.8.0 batch 1). Additive only; builds against frozen
#   v0.7 contracts in R/router_contract.R. Never modifies them.
# Math anchor (deep-research-report §v0.8): PositionState = base-space
#   point p. "position is state" was already A6 law in v0.7; this type
#   gives it a first-class carrier with coordinate/cell/layer/chart.

new_position_state <- function(address, coordinate, cell,
                               layer = 0L, chart = "grid") {
  if (!is.character(address) || length(address) == 0L || any(!nzchar(address))) {
    stop("`address` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.numeric(coordinate) || length(coordinate) != length(address)) {
    stop("`coordinate` must be numeric with one value per address element.",
         call. = FALSE)
  }
  if (!is.character(cell) || length(cell) != 1L || !nzchar(cell)) {
    stop("`cell` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.numeric(layer) || length(layer) != 1L || layer < 0 ||
      layer != as.integer(layer)) {
    stop("`layer` must be a single non-negative integer.", call. = FALSE)
  }
  if (!is.character(chart) || length(chart) != 1L || !nzchar(chart)) {
    stop("`chart` must be a single non-empty character.", call. = FALSE)
  }
  structure(
    list(
      address    = address,
      coordinate = coordinate,
      cell       = cell,
      layer      = as.integer(layer),
      chart      = chart
    ),
    class = "visualr_position_state"
  )
}

validate_position_state <- function(ps) {
  if (!inherits(ps, "visualr_position_state")) {
    stop("Expected a visualr_position_state.", call. = FALSE)
  }
  new_position_state(ps$address, ps$coordinate, ps$cell, ps$layer, ps$chart)
  invisible(TRUE)
}

# Merge attachment seam (report Step 1): attach without touching the
# frozen new_merge(). `$address` stays the compatibility field.
attach_position_state <- function(m, ps) {
  if (!inherits(m, "visualr_merge")) {
    stop("`m` must be a visualr_merge.", call. = FALSE)
  }
  validate_position_state(ps)
  # fail-closed: address identity must agree between merge and position state
  addr_chr <- paste(ps$address, collapse = "/")
  if (!is.null(m$address) && paste(m$address, collapse = "/") != addr_chr) {
    stop("PositionState address conflicts with merge$address (fail closed).",
         call. = FALSE)
  }
  m$position_state <- ps
  if (is.null(m$address)) m$address <- ps$address
  m
}

merge_position <- function(m) {
  if (!is.null(m$position_state)) return(m$position_state)
  if (!is.null(m$address)) {
    # compatibility projection from legacy scalar address
    return(new_position_state(m$address, seq_along(m$address), "legacy"))
  }
  stop("Merge has no position (neither position_state nor address).",
       call. = FALSE)
}