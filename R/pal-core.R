pal_state <- function(shells, core) {
  structure(
    list(
      shells = as.character(shells),
      core = as.character(core)
    ),
    class = "visualr_pal"
  )
}

validate_pal <- function(x) {
  stopifnot(inherits(x, "visualr_pal"))
  length(x$shells) >= 0 && length(x$core) == 1
}

encode_pal <- function(x) {
  validate_pal(x)
  out <- paste0("{", x$core, "}")
  for (s in rev(x$shells)) {
    out <- paste0("{", s, out, s, "}")
  }
  out
}

unfold_pal <- function(x) {
  validate_pal(x)
  c(x$shells, x$core, rev(x$shells))
}

mirror_address <- function(i, length_value) {
  length_value + 1L - i
}
