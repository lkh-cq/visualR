# == diamond_field / diamond_at: Layer 3 projection view =============
# visualr_pal -> order field (lambda = n - |p-c|_1), one-way.
#
# Audit ruling I2: output is ORDER (lambda), NOT distance.
# Single direction: no diamond_to_pal() inverse exists.
# Diamond area: 1 + 2*n*(n+1) non-NA cells.
#
# v0.2.1 (P1): diamond_at() provides LAZY order lookup without
# materializing the full field — CPU-first philosophy. diamond_field()
# is retained as the explicit materialization entry point.

#' @title Lazy order lookup at (x,y) — no field materialization
#' @description Compute the order lambda = n - |x| - |y| at a single
#'   point (0-indexed offset from center) without building the full
#'   (2n+1)^2 matrix. CPU-first: the field need never be materialized.
#' @param pal a visualr_pal object
#' @param x integer, column offset from center (0 = center)
#' @param y integer, row offset from center (0 = center)
#' @return integer order (0..n), or NA if outside the diamond
#'   (|x|+|y| > n)
#' @examples
#' diamond_at(new_pal_state(c("A","B","C","D"), "e"), 0, 0)
diamond_at <- function(pal, x, y) {
  validate_pal(pal)
  # v0.2.2 (P1): hard parameter-domain validation — x/y must be
  # integer-like scalars, finite, non-NA.
  check_offset <- function(v, nm) {
    if (!is.numeric(v) || length(v) != 1L || is.na(v) || !is.finite(v)) {
      stop(sprintf("`%s` must be a single finite numeric value.", nm),
           call. = FALSE)
    }
    if (v != floor(v)) {
      stop(sprintf("`%s` must be integer-like (got %s).", nm, v),
           call. = FALSE)
    }
    as.integer(v)
  }
  x <- check_offset(x, "x")
  y <- check_offset(y, "y")
  n <- length(pal$shells)
  if (abs(x) + abs(y) > n) return(NA_integer_)
  as.integer(n - abs(x) - abs(y))
}

diamond_field <- function(pal) {
  validate_pal(pal)

  n <- length(pal$shells)
  size <- 2L * n + 1L
  center <- n + 1L

  # Initialize matrix with NA
  mat <- matrix(NA_real_, nrow = size, ncol = size)

  # Fill diamond interior with order values
  # lambda(p) = n - |p - c|_1
  for (i in 1:size) {
    for (j in 1:size) {
      dist <- abs(i - center) + abs(j - center)
      order_val <- n - dist
      if (order_val >= 0) {
        mat[i, j] <- order_val
      }
    }
  }

  structure(
    list(
      matrix = mat,
      center = c(center, center),
      radius = as.integer(n),
      n = as.integer(n)
    ),
    class = CLASS_DIAMOND
  )
}

# == print method ====================================================

print.visualr_diamond <- function(x, ...) {
  k <- nrow(x$matrix)
  cat(sprintf("<visualr_diamond> %dx%d n=%d center=(%d,%d)\n",
              k, k, x$n, x$center[1], x$center[2]))
  print(x$matrix, na.print = ".", quote = FALSE)
  invisible(x)
}
