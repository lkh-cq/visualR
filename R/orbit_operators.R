# == Orbit operators: lane kernels for Topology Operator ABI v0.1 ====
# Concrete lane kernels replacing the identity placeholder. Each lane
# kernel has signature (orbit, phase, pack) — orbit is the endpoint
# pair (head, tail) or the singularity token; pack carries the mapping
# pack rules (P0-1: rules come from the pack, never globals).
#
# Frozen-spec mapping (sanyuan-runtime):
#   identity    — no change (baseline lane)
#   complement  — self-mirror involution C^2 = I (palindrome head==tail)
#   mirror      — swap head<->tail endpoints (orientation flip)
#   rotate      — orbit-table rotation (D->A->B->C->D cycle)
#   gamma       — local field step (cross -1 order, diagonal -2 order)
#
# R is the operator language; these kernels are the reference semantics
# for the C/Java execution fabrics.

# =====================================================================
# Kernel registry (lane-level, distinct from matrix-level operators)
# =====================================================================

# Package-level env for lane kernels (mirrors .visualR_operator_env).
.lane_kernel_env <- new.env(parent = emptyenv())

lane_kernel_register <- function(name, fn, overwrite = FALSE) {
  if (!is.character(name) || length(name) != 1L || name == "") {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("`fn` must be a function.", call. = FALSE)
  }
  builtins <- c("identity", "complement", "mirror", "rotate", "gamma")
  if (name %in% builtins && !overwrite && exists(name, envir = .lane_kernel_env, inherits = FALSE)) {
    stop(sprintf("'%s' is a built-in lane kernel (fail closed). Use overwrite=TRUE.",
                 name), call. = FALSE)
  }
  fmls <- names(formals(fn))
  if (length(fmls) < 3L && !("..." %in% fmls)) {
    stop("lane kernel must accept at least (orbit, phase, pack).", call. = FALSE)
  }
  assign(name, fn, envir = .lane_kernel_env)
  invisible(TRUE)
}

lane_kernel_get <- function(name) {
  if (!exists(name, envir = .lane_kernel_env, inherits = FALSE)) {
    stop(sprintf("Unknown lane kernel '%s' (fail closed).", name),
         call. = FALSE)
  }
  get(name, envir = .lane_kernel_env, inherits = FALSE)
}

lane_kernel_list <- function() {
  sort(ls(envir = .lane_kernel_env))
}

# =====================================================================
# Built-in kernels
# =====================================================================

#' @title Lane kernel: identity
#' @description Baseline lane kernel: returns the orbit unchanged.
#' @param orbit character vector of two endpoints (or singularity token).
#' @param phase current phase label.
#' @param pack mapping pack (rules source; unused by identity).
#' @return list(result, phase, action).
kernel_identity <- function(orbit, phase = "idle", pack = NULL) {
  list(result = orbit, phase = phase, action = "identity")
}

#' @title Lane kernel: complement (self-mirror involution)
#' @description Maps each endpoint through the complement table
#'   (C^2 = I). For a canonical palindrome orbit (head == tail) the
#'   complement maps the token; endpoints stay paired.
#' @param orbit character vector of two endpoints.
#' @param phase current phase label.
#' @param pack mapping pack (complement table source; uses
#'   pack$complement_table if present, else identity mapping).
#' @return list(result, phase, action = "complement").
kernel_complement <- function(orbit, phase = "idle", pack = NULL) {
  tbl <- if (!is.null(pack) && !is.null(pack$complement_table)) {
    pack$complement_table
  } else {
    c(A = "D", D = "A", B = "C", C = "B", e = "e")
  }
  map_one <- function(x) {
    if (is.na(x)) return(NA_character_)
    if (x %in% names(tbl)) unname(tbl[[x]]) else x
  }
  result <- vapply(orbit, map_one, character(1), USE.NAMES = FALSE)
  list(result = result, phase = phase, action = "complement")
}

#' @title Lane kernel: mirror (swap endpoints)
#' @description Orientation flip: swaps head and tail of the orbit.
#'   For a canonical palindrome (head == tail) this is identity, but
#'   for directional orbits it records the orientation flip.
#' @param orbit character vector of two endpoints.
#' @param phase current phase label.
#' @param pack mapping pack (unused; orientation is structural).
#' @return list(result, phase, action = "mirror").
kernel_mirror <- function(orbit, phase = "idle", pack = NULL) {
  if (length(orbit) == 1L) {
    # singularity lane: mirror of center is itself
    return(list(result = orbit, phase = phase, action = "mirror"))
  }
  result <- rev(orbit)
  list(result = result, phase = phase, action = "mirror")
}

#' @title Lane kernel: rotate (orbit-table rotation)
#' @description Rotates orbit values along the packing orbit cycle
#'   D->A->B->C->D. Uses the pack's orbit_table addresses when
#'   available (matrix-level semantics); at the lane level the rotation
#'   advances the token to the next orbit's token.
#' @param orbit character vector of two endpoints.
#' @param phase current phase label.
#' @param pack mapping pack (rotation table source).
#' @return list(result, phase, action = "rotate").
kernel_rotate <- function(orbit, phase = "idle", pack = NULL) {
  cycle <- c(A = "B", B = "C", C = "D", D = "A")
  rot_one <- function(x) {
    if (is.na(x)) return(NA_character_)
    if (x %in% names(cycle)) unname(cycle[[x]]) else x
  }
  result <- vapply(orbit, rot_one, character(1), USE.NAMES = FALSE)
  list(result = result, phase = phase, action = "rotate")
}

#' @title Lane kernel: gamma (local field step)
#' @description Local field transformation: cross cells step -1 order,
#'   diagonal cells step -2 order (frozen gamma_field rule). At the
#'   lane level this maps the endpoint token through the order-lowering
#'   table (A->B->C->D->e ladder, clamped at e).
#' @param orbit character vector of two endpoints.
#' @param phase current phase label.
#' @param pack mapping pack (unused; rule is frozen).
#' @return list(result, phase, action = "gamma").
kernel_gamma <- function(orbit, phase = "idle", pack = NULL) {
  step <- c(A = "B", B = "C", C = "D", D = "e", e = "e")
  step_one <- function(x) {
    if (is.na(x)) return(NA_character_)
    if (x %in% names(step)) unname(step[[x]]) else x
  }
  result <- vapply(orbit, step_one, character(1), USE.NAMES = FALSE)
  list(result = result, phase = phase, action = "gamma")
}

# Register builtins at package load (idempotent: env may already hold
# them if load_all() runs this more than once in a session).
.onLoad_lane_kernels <- function() {
  for (nm in c("identity", "complement", "mirror", "rotate", "gamma")) {
    if (!exists(nm, envir = .lane_kernel_env, inherits = FALSE)) {
      lane_kernel_register(nm, get(paste0("kernel_", nm)))
    }
  }
  invisible(TRUE)
}

# =====================================================================
# Lane dispatch helper: build a kernels list from names
# =====================================================================

#' @title Build a lane kernel dispatch list
#' @description Convenience: maps a single kernel name (or a named list
#'   per-lane) into the kernels argument expected by execute_lanes.
#' @param spec character (single kernel for all lanes), or named list
#'   with names in A/B/C/D/e (per-lane kernels).
#' @return named list of lane kernel FUNCTIONS.
#' @examples
#' lane_kernels("rotate")
#' lane_kernels(list(A = "gamma", B = "complement", e = "identity"))
lane_kernels <- function(spec) {
  if (is.character(spec) && length(spec) == 1L) {
    # One kernel for ALL lanes: A..Z orbits + e. Deeper states pick the
    # subset they need; missing labels are simply unused. (Branch-1:
    # dynamic orbit count — S_5 uses A..E + e.)
    fn <- lane_kernel_get(spec)
    out <- stats::setNames(lapply(c(LETTERS, "e"), function(nm) fn),
                           c(LETTERS, "e"))
  } else if (is.list(spec)) {
    if (is.null(names(spec)) || any(names(spec) == "")) {
      stop("lane spec entries must be named.", call. = FALSE)
    }
    out <- lapply(spec, function(s) {
      if (is.character(s) && length(s) == 1L) lane_kernel_get(s)
      else if (is.function(s)) s
      else stop("lane spec entries must be kernel names or functions.")
    })
    # Missing required labels default to identity (so partial specs work
    # for any depth): fill A..Z + e, preserving explicit entries.
    for (nm in c(LETTERS, "e")) {
      if (is.null(out[[nm]])) out[[nm]] <- lane_kernel_get("identity")
    }
  } else {
    stop("`spec` must be a kernel name or a named list.", call. = FALSE)
  }
  out
}

# =====================================================================
# execute_lanes integration (supports kernel name specs)
# =====================================================================

#' @title Execute lanes with kernel specs
#' @description Same as execute_lanes but accepts kernel name specs via
#'   lane_kernels() and passes the mapping pack to each kernel.
#' @param snap a \code{visualr_snapshot}.
#' @param kernels named list of kernel FUNCTIONS (default: all identity)
#'   OR a kernel-name spec accepted by lane_kernels().
#' @param pack mapping pack (default: resolved from the snapshot cell's
#'   pal mapping_pack_id).
#' @return named list of lane results.
execute_lanes_ops <- function(snap, kernels = NULL, pack = NULL) {
  if (!inherits(snap, "visualr_snapshot")) {
    stop("`snap` must be a visualr_snapshot.", call. = FALSE)
  }
  if (is.character(kernels) || is.list(kernels)) {
    kernels <- lane_kernels(kernels)
  }
  if (is.null(kernels)) {
    kernels <- lane_kernels("identity")
  }
  cell <- snap$cell
  if (is.null(pack)) {
    pack <- tryCatch(pal_resolve_pack(cell$origin$pal %||% cell$singularity),
                     error = function(e) NULL)
  }
  # Dynamic lanes: ONE lane per orbit (label order) + the singularity
  # lane. S_4 -> A/B/C/D + e; S_5 -> A/B/C/D/E + e. (Branch-1 audit
  # 2026-08-09: hard-coded 4 orbits dropped S_5+ shells.)
  lane_names <- names(cell$orbits)
  if (is.null(lane_names) || any(lane_names == "")) {
    lane_names <- LETTERS[seq_along(cell$orbits)]
  }
  out <- lapply(lane_names, function(nm) {
    kernels[[nm]](cell$orbits[[nm]], cell$phase, pack)
  })
  names(out) <- lane_names
  out[["e"]] <- kernels$e(cell$singularity, cell$phase, pack)
  out
}
