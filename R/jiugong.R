# == pal_to_jiugong / jiugong_to_pal: Layer 2 jiugong mapping ========
# pal_to_jiugong: visualr_pal -> visualr_jiugong (k x k matrix)
# jiugong_to_pal: visualr_jiugong -> visualr_pal
#
# Audit ruling R4: PAL jiugong mapping is separate from spatial window extraction.
# Applicable only when 2*length(shells)+1 is a perfect square.
# Invariant 3: jiugong_to_pal(pal_to_jiugong(S_4)) == S_4

pal_to_jiugong <- function(pal) {
  validate_pal(pal)

  unfolded <- unfold_pal(pal)
  n <- length(unfolded)

  # v0.2.2 (P1): jiugong is STRICTLY the S_4 -> 3x3 mapping per the
  # frozen spec (元九宫). Other perfect-square unfolded lengths
  # (S_0 -> 1x1, S_12 -> 5x5) are general square views, not jiugong:
  # use pal_to_square_view() for those.
  k <- sqrt(n)
  if (k != floor(k) || k != 3L) {
    stop(sprintf(
      "pal_to_jiugong is the S_4 -> 3x3 mapping only (unfolded length %d). Use pal_to_square_view() for general square views.",
      n
    ), call. = FALSE)
  }
  k <- 3L

  # Fill row-major: unfolded[1:k] -> row 1, etc.
  grid <- matrix(unfolded, nrow = k, ncol = k, byrow = TRUE)

  structure(
    list(
      grid = grid,
      mapping_pack_id = pal$mapping_pack_id
    ),
    class = CLASS_JIUGONG
  )
}

#' @title General square view: S_n -> k x k matrix (k^2 = unfolded length)
#' @description The general perfect-square projection. When the unfolded
#'   palindrome length is a perfect square (1, 9, 25, ...), the path can
#'   be read row-major into a k x k matrix. This is NOT the frozen
#'   S_4 -> 3x3 jiugong; it is the general square view (P1, v0.2.2).
#' @param pal a visualr_pal object
#' @return list with fields grid (k x k matrix), mapping_pack_id
#' @examples
#' pal_to_square_view(new_pal_state(c("A","B","C","D"), "e"))
pal_to_square_view <- function(pal) {
  validate_pal(pal)
  unfolded <- unfold_pal(pal)
  n <- length(unfolded)
  k <- sqrt(n)
  if (k != floor(k)) {
    stop(sprintf(
      "Unfolded length (%d) must be a perfect square for a square view.",
      n
    ), call. = FALSE)
  }
  k <- as.integer(k)
  grid <- matrix(unfolded, nrow = k, ncol = k, byrow = TRUE)
  list(grid = grid, mapping_pack_id = pal$mapping_pack_id)
}

jiugong_to_pal <- function(jiugong,
                           mapping_pack_id = NULL,
                           provenance = list()) {
  if (!inherits(jiugong, CLASS_JIUGONG)) {
    stop("`jiugong` must be a visualr_jiugong object.", call. = FALSE)
  }

  # Read back row-major: transpose then column-major vector
  unfolded <- as.vector(t(jiugong$grid))

  # Use jiugong's mapping_pack_id if not overridden
  if (is.null(mapping_pack_id)) {
    mapping_pack_id <- jiugong$mapping_pack_id
  }

  fold_pal(
    unfolded,
    mapping_pack_id = mapping_pack_id,
    provenance = provenance
  )
}

# == print method ====================================================

print.visualr_jiugong <- function(x, ...) {
  k <- nrow(x$grid)
  cat(sprintf("<visualr_jiugong> %dx%d mapping_pack=%s\n",
              k, k, x$mapping_pack_id))
  print(x$grid, quote = FALSE)
  invisible(x)
}
