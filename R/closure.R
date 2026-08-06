# ── closure_jiugong / compute_jiugong: Layer 2 emergence gate ──────
# Ported from mapping_pack.py closure() / compute() / op_orbit_rotate().
#
# Emergence operator contract (frozen):
#   Ω: M -> M, 3x3, shape_preserving
#   All components read the SAME snapshot, then commit atomically
#   (snapshot-commit transaction semantics, NOT multi-thread writes).
#   Result must pass the closure gate before being written back to
#   palindrome storage.
#
# Closure gate three results (frozen):
#   closed    -> satisfies complement & central symmetry, can fold back
#   transient -> computation intermediate state, keep as working state,
#                NOT writable to storage
#   recurse   -> asymmetry is next-dimension emergence signal

#' @title Closure gate for a 3x3 jiugong matrix
#' @description Evaluate a 3x3 matrix against the frozen closure gate.
#'   Returns one of "closed" (can fold back to palindrome), "transient"
#'   (computation intermediate, not storable), or "recurse" (asymmetry
#'   is a next-dimension emergence signal).
#' @param grid a 3x3 matrix (character or atomic)
#' @return single character: "closed" | "transient" | "recurse"
#' @examples
#' closure_jiugong(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE))
closure_jiugong <- function(grid) {
  if (!is.matrix(grid) || nrow(grid) != 3L || ncol(grid) != 3L) {
    stop("`grid` must be a 3x3 matrix.", call. = FALSE)
  }

  # 0) Symbol legality: every non-NA cell must be a frozen symbol
  #    (A/B/C/D/e) OR a lowercased stripped marker (a/b/c/d — from
  #    gamma_field output). Anything else is not a valid jiugong
  #    working state -> transient (cannot be stored).
  frozen <- c("A", "B", "C", "D", "e", "a", "b", "c", "d")
  vals <- as.vector(grid)
  if (any(!vals %in% frozen)) {
    return("transient")
  }

  # 1) Central inversion symmetry check (Sigma^2 = I)
  for (r in 1:3) {
    for (c in 1:3) {
      m <- mirror_addr(r, c)
      if (!identical(grid[r, c], grid[m[1], m[2]])) {
        return("recurse")  # symmetry break = emergence signal
      }
    }
  }

  # 2) Complement check: each orbit's two cells must hold equal values
  #    (self-complement C(x)=x means head cell == tail cell)
  for (sym in c("A", "B", "C", "D")) {
    entry <- ORBIT_TABLE[[sym]]
    v1 <- grid[entry$addr1[1], entry$addr1[2]]
    v2 <- grid[entry$addr2[1], entry$addr2[2]]
    if (!identical(v1, v2)) {
      return("transient")
    }
  }

  # 3) Foldability: try to collapse back to palindrome and re-expand
  tryCatch({
    collapsed <- jiugong_to_pal(structure(list(grid = grid,
                                               mapping_pack_id = DEFAULT_MAPPING_PACK_ID),
                                          class = CLASS_JIUGONG))
    reexpanded <- pal_to_jiugong(collapsed)$grid
    if (identical(reexpanded, grid)) {
      "closed"
    } else {
      "transient"
    }
  }, error = function(e) "transient")
}

#' @title Compute emergence operator on a 3x3 matrix
#' @description Apply a registered emergence operator Ω: M -> M with
#'   snapshot-commit transaction semantics. All components read the same
#'   snapshot, then write atomically. The result should be checked with
#'   \code{closure_jiugong()} before writing back to palindrome storage.
#' @param grid a 3x3 matrix
#' @param op single character, operator name. Built-ins: "identity",
#'   "orbit_rotate". Custom operators via \code{register_operator()}.
#' @return a 3x3 matrix (the transformed working state)
#' @examples
#' compute_jiugong(matrix(c("A","B","C","D","e","D","C","B","A"), 3, byrow=TRUE), "identity")
compute_jiugong <- function(grid, op = "identity") {
  if (!is.matrix(grid) || nrow(grid) != 3L || ncol(grid) != 3L) {
    stop("`grid` must be a 3x3 matrix.", call. = FALSE)
  }
  if (!is.character(op) || length(op) != 1L) {
    stop("`op` must be a single character.", call. = FALSE)
  }
  fn <- .visualR_operator_env[[op]]
  if (is.null(fn)) {
    stop(sprintf("Unknown emergence operator: '%s'. Registered: %s",
                 op, paste(sort(ls(.visualR_operator_env)), collapse = ", ")),
         call. = FALSE)
  }
  fn(grid)
}

#' @title Register a custom emergence operator
#' @description Add a shape-preserving operator Ω: 3x3 -> 3x3 to the
#'   registry. The operator must read a snapshot and commit atomically
#'   (copy-on-modify in R gives this naturally).
#' @param name single character, operator name
#' @param fn function taking a 3x3 matrix and returning a 3x3 matrix
#' @return invisible(NULL); registers for compute_jiugong()
#' @examples
#' register_operator("flip_diag", function(M) t(M))
register_operator <- function(name, fn) {
  if (!is.character(name) || length(name) != 1L || name == "") {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("`fn` must be a function.", call. = FALSE)
  }
  .visualR_operator_env[[name]] <- fn
  invisible(NULL)
}

# ── Package-level operator registry (module state) ───────────────────
.visualR_operator_env <- new.env(parent = emptyenv())

# identity: no change, used to verify round-trip
.visualR_operator_env$identity <- function(M) {
  M
}

# orbit_rotate: center e unchanged; four orbit groups rotate along
# EXPAND_ORDER (D->C->B->A->D). Demonstrates snapshot-commit: all
# components read the same snapshot, then write atomically.
.visualR_operator_env$orbit_rotate <- function(M) {
  snapshot <- M
  out <- M
  # orbit assignment: new position <- old orbit
  # D gets A's values, C gets D's, B gets C's, A gets B's
  orbit_map <- c(D = "A", C = "D", B = "C", A = "B")
  for (sym in EXPAND_ORDER) {
    if (sym == "e") next
    entry <- ORBIT_TABLE[[sym]]
    src <- orbit_map[[sym]]
    src_entry <- ORBIT_TABLE[[src]]
    v1 <- snapshot[src_entry$addr1[1], src_entry$addr1[2]]
    v2 <- snapshot[src_entry$addr2[1], src_entry$addr2[2]]
    out[entry$addr1[1], entry$addr1[2]] <- v1
    out[entry$addr2[1], entry$addr2[2]] <- v2
  }
  out
}
