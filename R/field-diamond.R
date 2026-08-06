diamond_value <- function(x, y, center = c(0, 0), shells = c("A", "B", "C", "D"), core = "E") {
  d <- abs(x - center[1]) + abs(y - center[2])
  levels <- c(core, rev(shells))
  if (d + 1L <= length(levels)) {
    levels[d + 1L]
  } else {
    NA_character_
  }
}

as_diamond <- function(radius = 4L, shells = c("A", "B", "C", "D"), core = "E") {
  grid <- expand.grid(
    x = -radius:radius,
    y = -radius:radius
  )
  grid$value <- mapply(
    diamond_value,
    grid$x,
    grid$y,
    MoreArgs = list(shells = shells, core = core)
  )
  grid
}
