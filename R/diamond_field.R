# ── diamond_field: Layer 3 projection view ──────────────────────────
# visualr_pal -> visualr_diamond (order field)
#
# Audit ruling I2: output is ORDER (lambda = n - |p-c|_1), NOT distance.
# Single direction: no diamond_to_pal() inverse exists.
# Diamond area: 1 + 2*n*(n+1) non-NA cells.

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

# ── print method ────────────────────────────────────────────────────

print.visualr_diamond <- function(x, ...) {
  k <- nrow(x$matrix)
  cat(sprintf("<visualr_diamond> %dx%d n=%d center=(%d,%d)\n",
              k, k, x$n, x$center[1], x$center[2]))
  print(x$matrix, na.print = ".", quote = FALSE)
  invisible(x)
}
