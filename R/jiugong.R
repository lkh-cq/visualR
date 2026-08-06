as_jiugong <- function(x) {
  path <- unfold_pal(x)
  if (length(path) != 9L) {
    stop("Jiugong view requires exactly 9 unfolded elements")
  }
  matrix(path, nrow = 3L, ncol = 3L, byrow = TRUE)
}

jiugong_closed <- function(m) {
  stopifnot(all(dim(m) == c(3L, 3L)))
  identical(m, m[3:1, 3:1])
}
