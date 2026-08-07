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

  # Check that n is a perfect square
  k <- sqrt(n)
  if (k != floor(k)) {
    stop(sprintf(
      "Unfolded length (%d) must be a perfect square for jiugong mapping.",
      n
    ), call. = FALSE)
  }
  k <- as.integer(k)

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
