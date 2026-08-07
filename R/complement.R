# == complement_pal / mirror_addr: frozen symmetry operators ========-
# Ported from /mnt/d/sanyuan-runtime/mapping_pack.py (2026-08-05 frozen).
#
# Frozen invariants (sanyuan-runtime v0.2):
#   C^2 = I   complement is an involution (self-mirror: palindrome head==tail)
#   Sigma^2 = I   central inversion M_ij = M_(4-i,4-j) (1-indexed, 3x3)
#
# These two operators are REQUIRED by the frozen spec (complement/invert were
# incorrectly dropped from the Trae third-party v0.1 plan; restored here).

# == Fourth-dimension fixed mapping table (user-frozen 2026-08-05) ====
# storage role | head | tail | jiugong coords (1-indexed)
ORBIT_TABLE <- list(
  A = list(head = 1L, tail = 9L, addr1 = c(1L, 1L), addr2 = c(3L, 3L)),
  B = list(head = 2L, tail = 8L, addr1 = c(1L, 2L), addr2 = c(3L, 2L)),
  C = list(head = 3L, tail = 7L, addr1 = c(1L, 3L), addr2 = c(3L, 1L)),
  D = list(head = 4L, tail = 6L, addr1 = c(2L, 1L), addr2 = c(2L, 3L)),
  e = list(head = 5L, tail = 5L, addr1 = c(2L, 2L), addr2 = c(2L, 2L))
)

# Center-outward expand order (palindrome depth order, NOT geometric distance)
EXPAND_ORDER <- c("e", "D", "C", "B", "A")

#' @title Central inversion (mirror address)
#' @description Frozen Sigma: (r,c) -> (4-r, 4-c) in 1-indexed 3x3 jiugong.
#'   Invariant: Sigma^2 = I (applying twice returns the original address).
#' @param row integer, row coordinate (1..3)
#' @param col integer, column coordinate (1..3)
#' @return integer vector of length 2: c(new_row, new_col)
#' @examples
#' mirror_addr(1L, 1L)  # c(3, 3)
#' mirror_addr(2L, 2L)  # c(2, 2) -- center is fixed point
mirror_addr <- function(row, col) {
  if (!is.numeric(row) || !is.numeric(col) ||
      length(row) != 1 || length(col) != 1) {
    stop("`row` and `col` must be single numeric values.", call. = FALSE)
  }
  r <- as.integer(row); c <- as.integer(col)
  if (r < 1 || r > 3 || c < 1 || c > 3) {
    stop("Coordinates must be in 1..3 (3x3 jiugong).", call. = FALSE)
  }
  c(4L - r, 4L - c)
}

#' @title Complement mapping (C^2 = I)
#' @description Apply the frozen complement rule to a symbol.
#'   Default: self-complement C(x) = x (palindrome head==tail, e.g. DNA
#'   palindromic recognition sites). A custom involution table can be
#'   supplied for domain adaptation; the table MUST be an involution
#'   (C(C(x)) = x), verified at construction.
#' @param pal a visualr_pal object
#' @param table optional named character vector, e.g. c(A="T", T="A").
#'   Missing symbols map to themselves. NULL = self-complement (default).
#' @return a new visualr_pal with complemented shells/core symbols.
#' @examples
#' complement_pal(new_pal_state(c("A","B"), "C"))
#' complement_pal(S4, table = c(A="T", T="A", B="G", G="B"))
complement_pal <- function(pal, table = NULL) {
  validate_pal(pal)

  # Validate involution: C(C(x)) = x for every key
  if (!is.null(table)) {
    if (!is.character(table) || is.null(names(table))) {
      stop("`table` must be a named character vector.", call. = FALSE)
    }
    if (anyNA(table) || anyNA(names(table)) || any(names(table) == "")) {
      stop("`table` must have non-NA, non-empty names.", call. = FALSE)
    }
    for (k in names(table)) {
      v <- table[[k]]
      back <- table[[v]]
      if (is.na(back) || back != k) {
        stop(sprintf("Complement table must be an involution: C(%s)=%s but C(%s)!=%s",
                     k, v, v, k), call. = FALSE)
      }
    }
  }

  comp <- function(x) {
    if (is.null(table)) return(x)              # self-complement default
    if (!x %in% names(table)) return(x)        # unregistered: self-complement
    table[[x]]
  }

  new_pal_state(
    shells = vapply(pal$shells, comp, character(1), USE.NAMES = FALSE),
    core   = comp(pal$core),
    mapping_pack_id = pal$mapping_pack_id,
    provenance = pal$provenance
  )
}

#' @title Locate symbol in fourth-dimension mapping table
#' @description O(1) lookup of a symbol's head/tail indices and jiugong
#'   coordinates. Ported from MappingPack.locate() (Python reference).
#' @param sym single character, one of A/B/C/D/e
#' @return list with symbol, complement, head_index, tail_index, head_addr,
#'   tail_addr, orbit, mirror_tail_addr
#' @examples
#' locate("D")
locate <- function(sym) {
  if (!is.character(sym) || length(sym) != 1 || is.na(sym)) {
    stop("`sym` must be a single character.", call. = FALSE)
  }
  if (!sym %in% names(ORBIT_TABLE)) {
    stop(sprintf("Operator %s not in the fourth-dimension mapping table.", sym),
         call. = FALSE)
  }
  entry <- ORBIT_TABLE[[sym]]
  list(
    symbol = sym,
    complement = sym,  # v0.1 default self-complement C(x)=x
    head_index = entry$head,
    tail_index = entry$tail,
    head_addr = entry$addr1,
    tail_addr = entry$addr2,
    orbit = list(entry$addr1, entry$addr2),
    mirror_tail_addr = mirror_addr(entry$addr1[1], entry$addr1[2])
  )
}
