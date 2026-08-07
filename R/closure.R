# == closure_check / transition_policy / compute_jiugong =============
# v0.2.1 Semantic Hardening:
#   P0-5: structure fact (closure) SEPARATED from scheduling decision
#         (transition policy). closure_check answers closed/not_closed;
#         transition_policy decides recurse/promote/reject.
#   P0-1: runtime rules come from the resolved mapping pack, NOT from
#         global constants.
#
# Emergence operator contract:
#   Omega: M -> M, 3x3, shape_preserving
#   All components read the SAME snapshot, then commit atomically
#   (snapshot-commit transaction semantics).
#   Result must pass the closure gate before being written back to
#   palindrome storage.

#' @title Closure fact check: is this 3x3 matrix closed?
#' @description Structural fact only. A matrix is "closed" when it is
#'   (a) composed of legal symbols from the resolved mapping pack
#'       (plus stripped markers a/b/c/d from gamma output),
#'   (b) symmetric under central inversion (Sigma^2 = I),
#'   (c) orbit-complement consistent (head cell == tail cell),
#'   (d) foldable: fold-back then re-expand reproduces the matrix.
#'   Returns logical TRUE/FALSE. Scheduling decisions (recurse vs
#'   transient vs promote) belong in transition_policy().
#' @param grid a 3x3 matrix
#' @param mapping_pack_id single character, pack whose rules drive the
#'   check (default: DEFAULT_MAPPING_PACK_ID)
#' @return logical: TRUE if closed, FALSE otherwise
#' @examples
#' closure_check(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
closure_check <- function(grid, mapping_pack_id = DEFAULT_MAPPING_PACK_ID) {
  if (!is.matrix(grid) || nrow(grid) != 3L || ncol(grid) != 3L) {
    stop("`grid` must be a 3x3 matrix.", call. = FALSE)
  }
  pack <- resolve_mapping_pack(mapping_pack_id)   # P0-1: fail closed

  # a) Symbol legality: pack symbols + stripped markers (gamma output)
  legal <- c(pack$frozen_symbols, tolower(pack$frozen_symbols))
  vals <- as.vector(grid)
  if (any(!vals %in% legal)) {
    return(FALSE)
  }

  # b) Central inversion symmetry
  for (r in 1:3) {
    for (c in 1:3) {
      m <- mirror_addr(r, c)
      if (!identical(grid[r, c], grid[m[1], m[2]])) {
        return(FALSE)
      }
    }
  }

  # c) Complement consistency: orbit head == orbit tail (self-complement)
  for (sym in pack$expand_order) {
    if (sym %in% c("e", "E")) next
    entry <- pack$orbit_table[[sym]]
    if (is.null(entry)) next
    v1 <- grid[entry$addr1[1], entry$addr1[2]]
    v2 <- grid[entry$addr2[1], entry$addr2[2]]
    if (!identical(v1, v2)) {
      return(FALSE)
    }
  }

  # d) Foldability: fold-back then re-expand == original
  tryCatch({
    collapsed <- jiugong_to_pal(structure(list(grid = grid,
                                               mapping_pack_id = mapping_pack_id),
                                          class = CLASS_JIUGONG))
    reexpanded <- pal_to_jiugong(collapsed)$grid
    identical(reexpanded, grid)
  }, error = function(e) FALSE)
}

#' @title Transition policy: what to do with a non-closed state
#' @description Scheduling decision layer, SEPARATE from the closure
#'   fact. Given a 3x3 matrix and its closure status, decide the next
#'   action:
#'   \itemize{
#'     \item \code{closed}   -> "promote" (fold back to storage)
#'     \item symmetry-broken -> "recurse" (asymmetry = emergence signal)
#'     \item otherwise       -> "transient" (keep as working state)
#'     \item illegal symbols -> "reject"
#'   }
#'   NOTE (P0-7): recurse-on-asymmetry is an EXPERIMENTAL scheduling
#'   candidate, not a frozen axiom. Change the policy here without
#'   touching the closure fact.
#' @param grid a 3x3 matrix
#' @param mapping_pack_id single character, pack id
#' @return single character: "promote" | "transient" | "recurse" | "reject"
#' @examples
#' transition_policy(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
transition_policy <- function(grid, mapping_pack_id = DEFAULT_MAPPING_PACK_ID) {
  if (!is.matrix(grid) || nrow(grid) != 3L || ncol(grid) != 3L) {
    stop("`grid` must be a 3x3 matrix.", call. = FALSE)
  }
  pack <- resolve_mapping_pack(mapping_pack_id)

  # Illegal symbols -> reject (never a computation state)
  legal <- c(pack$frozen_symbols, tolower(pack$frozen_symbols))
  if (any(!as.vector(grid) %in% legal)) {
    return("reject")
  }

  # Closed -> promote (fold back to storage)
  if (closure_check(grid, mapping_pack_id)) {
    return("promote")
  }

  # Symmetry break -> recurse (EXPERIMENTAL scheduling candidate)
  for (r in 1:3) {
    for (c in 1:3) {
      m <- mirror_addr(r, c)
      if (!identical(grid[r, c], grid[m[1], m[2]])) {
        return("recurse")
      }
    }
  }

  # Otherwise: computation intermediate
  "transient"
}

# Backward-compatible three-way gate (frozen v0.2 semantics):
#   "closed"    <- promote
#   "transient" <- transient
#   "recurse"   <- recurse
# Kept for existing tests/callers; NEW code should use closure_check +
# transition_policy directly.
closure_jiugong <- function(grid, mapping_pack_id = DEFAULT_MAPPING_PACK_ID) {
  switch(transition_policy(grid, mapping_pack_id),
         promote = "closed",
         transient = "transient",
         recurse = "recurse",
         reject = "transient")
}

#' @title Compute emergence operator on a 3x3 matrix
#' @description Apply a registered emergence operator Omega: M -> M with
#'   snapshot-commit transaction semantics. All components read the same
#'   snapshot, then write atomically. The result should be checked with
#'   \code{closure_check()} before writing back to palindrome storage.
#' @param grid a 3x3 matrix
#' @param op single character, operator name. Built-ins: "identity",
#'   "orbit_rotate". Custom operators via \code{register_operator()}.
#' @param mapping_pack_id single character, pack whose orbit table
#'   drives the operator (default: DEFAULT_MAPPING_PACK_ID)
#' @return a 3x3 matrix (the transformed working state)
#' @examples
#' compute_jiugong(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE), "identity")
compute_jiugong <- function(grid, op = "identity",
                            mapping_pack_id = DEFAULT_MAPPING_PACK_ID) {
  if (!is.matrix(grid) || nrow(grid) != 3L || ncol(grid) != 3L) {
    stop("`grid` must be a 3x3 matrix.", call. = FALSE)
  }
  if (!is.character(op) || length(op) != 1L) {
    stop("`op` must be a single character.", call. = FALSE)
  }
  pack <- resolve_mapping_pack(mapping_pack_id)   # P0-1: fail closed
  fn <- .visualR_operator_env[[op]]
  if (is.null(fn)) {
    stop(sprintf("Unknown emergence operator: '%s'. Registered: %s",
                 op, paste(sort(ls(.visualR_operator_env)), collapse = ", ")),
         call. = FALSE)
  }
  # Operators receive (grid, pack) so they use pack rules, not globals
  out <- fn(grid, pack)
  # v0.2.2 (P1): enforce the operator contract at call time too
  # (a registered op could still misbehave on non-canonical input).
  if (!is.matrix(out) || nrow(out) != 3L || ncol(out) != 3L) {
    stop(sprintf("Operator '%s' returned %s, not a 3x3 matrix (contract violated).",
                 op, paste(dim(out), collapse = "x")), call. = FALSE)
  }
  if (is.numeric(out) || is.logical(out)) {
    stop(sprintf("Operator '%s' returned a %s matrix; character required (contract violated).",
                 op, typeof(out)), call. = FALSE)
  }
  out
}

#' @title Register a custom emergence operator
#' @description Add a shape-preserving operator Omega: 3x3 -> 3x3 to the
#'   registry. v0.2.1 ABI: the operator receives (grid, pack) and MUST
#'   return a 3x3 matrix. Built-ins cannot be overwritten unless
#'   \code{overwrite=TRUE}.
#' @param name single character, operator name
#' @param fn function(grid, pack) returning a 3x3 matrix
#' @param overwrite logical, allow overwriting a built-in.
#'   Default FALSE (fail closed).
#' @return invisible(NULL); registers for compute_jiugong()
#' @examples
#' register_operator("flip_diag", function(M, pack) t(M))
register_operator <- function(name, fn, overwrite = FALSE) {
  if (!is.character(name) || length(name) != 1L || name == "") {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("`fn` must be a function.", call. = FALSE)
  }
  builtins <- c("identity", "orbit_rotate")
  if (name %in% builtins && !overwrite) {
    stop(sprintf("'%s' is a built-in operator (fail closed). Use overwrite=TRUE.",
                 name), call. = FALSE)
  }
  # ABI check: operator must accept (grid, pack) shape -- verified lazily
  # at call time by compute_jiugong; here we only check arity allows 2.
  fmls <- names(formals(fn))
  if (length(fmls) < 2L && !("..." %in% fmls)) {
    stop("Operator ABI: fn must accept (grid, pack).", call. = FALSE)
  }
  # v0.2.2 (P1): probe the operator once with a canonical grid to
  # validate its contract at registration time.
  probe <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  pack <- resolve_mapping_pack(DEFAULT_MAPPING_PACK_ID)
  out <- tryCatch(fn(probe, pack), error = function(e) {
    stop(sprintf("Operator '%s' probe failed: %s", name, conditionMessage(e)),
         call. = FALSE)
  })
  if (!is.matrix(out) || nrow(out) != 3L || ncol(out) != 3L) {
    stop(sprintf("Operator '%s' must return a 3x3 matrix (probe returned %s).",
                 name, paste(dim(out), collapse = "x")), call. = FALSE)
  }
  if (is.numeric(out) || is.logical(out)) {
    stop(sprintf("Operator '%s' must return a character 3x3 matrix (got %s).",
                 name, typeof(out)), call. = FALSE)
  }
  .visualR_operator_env[[name]] <- fn
  invisible(NULL)
}

# == Package-level operator registry (module state) ==================
.visualR_operator_env <- new.env(parent = emptyenv())

# identity: no change, used to verify round-trip
.visualR_operator_env$identity <- function(M, pack) {
  M
}

# orbit_rotate: center e unchanged; four orbit groups rotate along
# pack$expand_order (D->C->B->A->D). Snapshot-commit: all components
# read the same snapshot, then write atomically.
.visualR_operator_env$orbit_rotate <- function(M, pack) {
  snapshot <- M
  out <- M
  orbit_map <- c(D = "A", C = "D", B = "C", A = "B")
  orbit_table <- pack$orbit_table   # P0-1: pack rules, not globals
  for (sym in pack$expand_order) {
    if (sym == "e") next
    entry <- orbit_table[[sym]]
    if (is.null(entry)) next
    src <- orbit_map[[sym]]
    src_entry <- orbit_table[[src]]
    if (is.null(src_entry)) next
    v1 <- snapshot[src_entry$addr1[1], src_entry$addr1[2]]
    v2 <- snapshot[src_entry$addr2[1], src_entry$addr2[2]]
    out[entry$addr1[1], entry$addr1[2]] <- v1
    out[entry$addr2[1], entry$addr2[2]] <- v2
  }
  out
}
